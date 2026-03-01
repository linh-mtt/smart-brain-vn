use std::sync::Arc;

use validator::Validate;

use crate::auth::jwt::{create_access_token, create_refresh_token};
use crate::auth::password::{hash_password, verify_password};
use crate::config::Config;
use crate::dto::auth::{AuthResponse, CreateUserRequest, LoginRequest, RefreshTokenRequest, UserResponse};
use crate::error::{ApiError, ApiResult};
use crate::models::user::UserRole;
use crate::repository::token_repository::TokenRepository;
use crate::repository::user_repository::UserRepository;

pub struct AuthService<U: UserRepository, T: TokenRepository> {
    user_repo: Arc<U>,
    token_repo: Arc<T>,
    config: Arc<Config>,
}

impl<U: UserRepository, T: TokenRepository> AuthService<U, T> {
    pub fn new(user_repo: Arc<U>, token_repo: Arc<T>, config: Arc<Config>) -> Self {
        Self {
            user_repo,
            token_repo,
            config,
        }
    }

    pub async fn register(&self, body: &CreateUserRequest) -> ApiResult<AuthResponse> {
        body.validate()
            .map_err(|e| ApiError::ValidationError(e.to_string()))?;

        // Check duplicate email
        if self.user_repo.email_exists(&body.email).await? {
            return Err(ApiError::Conflict(
                "A user with this email already exists".to_string(),
            ));
        }

        // Check duplicate username
        if self.user_repo.username_exists(&body.username).await? {
            return Err(ApiError::Conflict(
                "This username is already taken".to_string(),
            ));
        }

        // Hash password
        let password_hash = hash_password(&body.password)?;

        let role = body
            .role
            .as_deref()
            .map(UserRole::from_str_value)
            .unwrap_or(UserRole::Student);

        let grade_level = body.grade_level.unwrap_or(1);

        // Create user
        let user = self
            .user_repo
            .create(
                &body.email,
                &body.username,
                &password_hash,
                body.display_name.as_deref(),
                grade_level,
                body.age,
                &role,
            )
            .await?;

        tracing::info!("New user registered: {} ({})", user.username, user.email);

        // Generate tokens
        let access_token = create_access_token(&user, &self.config)?;
        let refresh_token = create_refresh_token(&user, &self.config)?;

        // Store refresh token in Redis
        let refresh_ttl = self.config.jwt_refresh_expires_in.as_secs();
        self.token_repo
            .store_refresh_token(user.id, &refresh_token, refresh_ttl)
            .await?;

        Ok(AuthResponse {
            user: UserResponse::from(user),
            access_token,
            refresh_token,
        })
    }

    pub async fn login(&self, body: &LoginRequest) -> ApiResult<AuthResponse> {
        body.validate()
            .map_err(|e| ApiError::ValidationError(e.to_string()))?;

        // Find user by email
        let user = self
            .user_repo
            .find_by_email(&body.email)
            .await?
            .ok_or(ApiError::Unauthorized)?;

        // Verify password
        let is_valid = verify_password(&body.password, &user.password_hash)?;
        if !is_valid {
            return Err(ApiError::Unauthorized);
        }

        tracing::info!("User logged in: {} ({})", user.username, user.email);

        // Generate tokens
        let access_token = create_access_token(&user, &self.config)?;
        let refresh_token = create_refresh_token(&user, &self.config)?;

        // Store refresh token
        let refresh_ttl = self.config.jwt_refresh_expires_in.as_secs();
        self.token_repo
            .store_refresh_token(user.id, &refresh_token, refresh_ttl)
            .await?;

        Ok(AuthResponse {
            user: UserResponse::from(user),
            access_token,
            refresh_token,
        })
    }

    pub async fn refresh(&self, body: &RefreshTokenRequest) -> ApiResult<AuthResponse> {
        // Validate refresh token exists in Redis
        let user_id = self
            .token_repo
            .get_refresh_token(&body.refresh_token)
            .await?
            .ok_or(ApiError::Unauthorized)?;

        // Delete old refresh token (rotation)
        self.token_repo
            .delete_refresh_token(&body.refresh_token)
            .await?;

        // Fetch user from database
        let user = self
            .user_repo
            .find_by_id(user_id)
            .await?
            .ok_or(ApiError::Unauthorized)?;

        // Generate new token pair
        let access_token = create_access_token(&user, &self.config)?;
        let refresh_token = create_refresh_token(&user, &self.config)?;

        // Store new refresh token
        let refresh_ttl = self.config.jwt_refresh_expires_in.as_secs();
        self.token_repo
            .store_refresh_token(user.id, &refresh_token, refresh_ttl)
            .await?;

        tracing::debug!("Token refreshed for user: {}", user.email);

        Ok(AuthResponse {
            user: UserResponse::from(user),
            access_token,
            refresh_token,
        })
    }

    pub async fn logout(&self, refresh_token: &str) -> ApiResult<()> {
        self.token_repo.delete_refresh_token(refresh_token).await?;

        tracing::debug!("User logged out, refresh token deleted");
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use async_trait::async_trait;
    use chrono::Utc;
    use std::collections::HashMap;
    use std::time::Duration;
    use tokio::sync::Mutex;
    use uuid::Uuid;

    use crate::domain::user::DomainUser;
    use crate::models::user::UserRole;

    // ─── Mock Repositories ──────────────────────────────────────────────────

    #[derive(Default)]
    struct MockUserRepository {
        users: Arc<Mutex<HashMap<Uuid, DomainUser>>>,
        users_by_email: Arc<Mutex<HashMap<String, DomainUser>>>,
        users_by_username: Arc<Mutex<HashMap<String, DomainUser>>>,
    }

    #[async_trait]
    impl UserRepository for MockUserRepository {
        async fn find_by_email(&self, email: &str) -> ApiResult<Option<DomainUser>> {
            Ok(self.users_by_email.lock().await.get(email).cloned())
        }

        async fn find_by_id(&self, id: Uuid) -> ApiResult<Option<DomainUser>> {
            Ok(self.users.lock().await.get(&id).cloned())
        }

        async fn email_exists(&self, email: &str) -> ApiResult<bool> {
            Ok(self.users_by_email.lock().await.contains_key(email))
        }

        async fn username_exists(&self, username: &str) -> ApiResult<bool> {
            Ok(self.users_by_username.lock().await.contains_key(username))
        }

        async fn create(
            &self,
            email: &str,
            username: &str,
            password_hash: &str,
            display_name: Option<&str>,
            grade_level: i32,
            age: Option<i32>,
            role: &UserRole,
        ) -> ApiResult<DomainUser> {
            let now = Utc::now();
            let user = DomainUser {
                id: Uuid::new_v4(),
                email: email.to_string(),
                username: username.to_string(),
                password_hash: password_hash.to_string(),
                display_name: display_name.map(String::from),
                avatar_url: None,
                grade_level,
                age,
                role: role.clone(),
                is_active: true,
                created_at: now,
                updated_at: now,
            };

            self.users.lock().await.insert(user.id, user.clone());
            self.users_by_email
                .lock()
                .await
                .insert(email.to_string(), user.clone());
            self.users_by_username
                .lock()
                .await
                .insert(username.to_string(), user.clone());

            Ok(user)
        }
    }

    #[derive(Default)]
    struct MockTokenRepository {
        tokens: Arc<Mutex<HashMap<String, Uuid>>>,
    }

    #[async_trait]
    impl TokenRepository for MockTokenRepository {
        async fn store_refresh_token(
            &self,
            user_id: Uuid,
            token: &str,
            _ttl_seconds: u64,
        ) -> ApiResult<()> {
            self.tokens
                .lock()
                .await
                .insert(token.to_string(), user_id);
            Ok(())
        }

        async fn get_refresh_token(&self, token: &str) -> ApiResult<Option<Uuid>> {
            Ok(self.tokens.lock().await.get(token).copied())
        }

        async fn delete_refresh_token(&self, token: &str) -> ApiResult<()> {
            self.tokens.lock().await.remove(token);
            Ok(())
        }
    }

    // ─── Test Helpers ───────────────────────────────────────────────────────

    fn test_config() -> Config {
        Config {
            database_url: "postgres://test:test@localhost/test".to_string(),
            redis_url: "redis://localhost:6379".to_string(),
            jwt_secret: "test-secret-key-that-is-at-least-32-characters-long".to_string(),
            jwt_access_expires_in: Duration::from_secs(900),
            jwt_refresh_expires_in: Duration::from_secs(604800),
            server_host: "0.0.0.0".to_string(),
            server_port: 8080,
            environment: crate::config::Environment::Dev,
        }
    }

    fn create_service() -> (
        AuthService<MockUserRepository, MockTokenRepository>,
        Arc<MockUserRepository>,
        Arc<MockTokenRepository>,
    ) {
        let user_repo = Arc::new(MockUserRepository::default());
        let token_repo = Arc::new(MockTokenRepository::default());
        let config = Arc::new(test_config());

        let service = AuthService::new(user_repo.clone(), token_repo.clone(), config);
        (service, user_repo, token_repo)
    }

    fn register_request() -> CreateUserRequest {
        CreateUserRequest {
            email: "test@example.com".to_string(),
            username: "testuser".to_string(),
            password: "securepassword123".to_string(),
            display_name: Some("Test User".to_string()),
            grade_level: Some(3),
            age: Some(8),
            role: None,
        }
    }

    // ─── Tests ──────────────────────────────────────────────────────────────

    #[tokio::test]
    async fn test_register_success() {
        let (service, _user_repo, token_repo) = create_service();
        let req = register_request();

        let result = service.register(&req).await;
        assert!(result.is_ok(), "Register should succeed: {:?}", result.err());

        let response = result.unwrap();
        assert_eq!(response.user.email, "test@example.com");
        assert_eq!(response.user.username, "testuser");
        assert!(!response.access_token.is_empty());
        assert!(!response.refresh_token.is_empty());

        // Verify refresh token was stored
        let stored = token_repo.tokens.lock().await;
        assert_eq!(stored.len(), 1);
    }

    #[tokio::test]
    async fn test_register_duplicate_email() {
        let (service, _user_repo, _token_repo) = create_service();
        let req = register_request();

        // First registration
        service.register(&req).await.unwrap();

        // Second registration with same email
        let result = service.register(&req).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            ApiError::Conflict(msg) => assert!(msg.contains("email")),
            e => panic!("Expected Conflict, got {:?}", e),
        }
    }

    #[tokio::test]
    async fn test_register_duplicate_username() {
        let (service, _user_repo, _token_repo) = create_service();

        let req1 = register_request();
        service.register(&req1).await.unwrap();

        // Different email, same username
        let req2 = CreateUserRequest {
            email: "other@example.com".to_string(),
            ..register_request()
        };

        let result = service.register(&req2).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            ApiError::Conflict(msg) => assert!(msg.contains("username")),
            e => panic!("Expected Conflict, got {:?}", e),
        }
    }

    #[tokio::test]
    async fn test_login_success() {
        let (service, _user_repo, _token_repo) = create_service();

        // Register first
        let reg_req = register_request();
        service.register(&reg_req).await.unwrap();

        // Login
        let login_req = LoginRequest {
            email: "test@example.com".to_string(),
            password: "securepassword123".to_string(),
        };

        let result = service.login(&login_req).await;
        assert!(result.is_ok(), "Login should succeed: {:?}", result.err());

        let response = result.unwrap();
        assert_eq!(response.user.email, "test@example.com");
        assert!(!response.access_token.is_empty());
    }

    #[tokio::test]
    async fn test_login_wrong_password() {
        let (service, _user_repo, _token_repo) = create_service();

        // Register first
        service.register(&register_request()).await.unwrap();

        // Login with wrong password
        let login_req = LoginRequest {
            email: "test@example.com".to_string(),
            password: "wrongpassword123".to_string(),
        };

        let result = service.login(&login_req).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            ApiError::Unauthorized => {}
            e => panic!("Expected Unauthorized, got {:?}", e),
        }
    }

    #[tokio::test]
    async fn test_login_nonexistent_user() {
        let (service, _user_repo, _token_repo) = create_service();

        let login_req = LoginRequest {
            email: "nobody@example.com".to_string(),
            password: "somepassword123".to_string(),
        };

        let result = service.login(&login_req).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            ApiError::Unauthorized => {}
            e => panic!("Expected Unauthorized, got {:?}", e),
        }
    }

    #[tokio::test]
    async fn test_refresh_success() {
        let (service, _user_repo, token_repo) = create_service();

        // Register to get tokens
        let reg_response = service.register(&register_request()).await.unwrap();
        let old_refresh = reg_response.refresh_token.clone();

        // Refresh
        let refresh_req = RefreshTokenRequest {
            refresh_token: old_refresh.clone(),
        };

        let result = service.refresh(&refresh_req).await;
        assert!(result.is_ok(), "Refresh should succeed: {:?}", result.err());

        let response = result.unwrap();
        assert!(!response.access_token.is_empty());
        assert!(!response.refresh_token.is_empty());
        assert_ne!(
            response.refresh_token, old_refresh,
            "New refresh token should differ"
        );

        // Old token should be deleted
        let tokens = token_repo.tokens.lock().await;
        assert!(!tokens.contains_key(&old_refresh));
        // New token should be stored
        assert!(tokens.contains_key(&response.refresh_token));
    }

    #[tokio::test]
    async fn test_refresh_invalid_token() {
        let (service, _user_repo, _token_repo) = create_service();

        let refresh_req = RefreshTokenRequest {
            refresh_token: "invalid-token".to_string(),
        };

        let result = service.refresh(&refresh_req).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            ApiError::Unauthorized => {}
            e => panic!("Expected Unauthorized, got {:?}", e),
        }
    }

    #[tokio::test]
    async fn test_logout() {
        let (service, _user_repo, token_repo) = create_service();

        // Register to get tokens
        let reg_response = service.register(&register_request()).await.unwrap();
        let refresh_token = reg_response.refresh_token.clone();

        // Verify token exists
        assert!(token_repo
            .tokens
            .lock()
            .await
            .contains_key(&refresh_token));

        // Logout
        let result = service.logout(&refresh_token).await;
        assert!(result.is_ok());

        // Token should be deleted
        assert!(!token_repo
            .tokens
            .lock()
            .await
            .contains_key(&refresh_token));
    }
}
