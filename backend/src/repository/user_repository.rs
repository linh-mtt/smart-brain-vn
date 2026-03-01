use async_trait::async_trait;
use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::user::DomainUser;
use crate::error::ApiResult;
use crate::models::user::{User, UserRole};

#[async_trait]
pub trait UserRepository: Send + Sync {
    async fn find_by_email(&self, email: &str) -> ApiResult<Option<DomainUser>>;
    async fn find_by_id(&self, id: Uuid) -> ApiResult<Option<DomainUser>>;
    async fn email_exists(&self, email: &str) -> ApiResult<bool>;
    async fn username_exists(&self, username: &str) -> ApiResult<bool>;
    async fn create(
        &self,
        email: &str,
        username: &str,
        password_hash: &str,
        display_name: Option<&str>,
        grade_level: i32,
        age: Option<i32>,
        role: &UserRole,
    ) -> ApiResult<DomainUser>;
}

pub struct PgUserRepository {
    pool: PgPool,
}

impl PgUserRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

fn user_to_domain(user: User) -> DomainUser {
    DomainUser {
        id: user.id,
        email: user.email,
        username: user.username,
        password_hash: user.password_hash,
        display_name: user.display_name,
        avatar_url: user.avatar_url,
        grade_level: user.grade_level,
        age: user.age,
        role: user.role,
        is_active: user.is_active,
        created_at: user.created_at,
        updated_at: user.updated_at,
    }
}

#[async_trait]
impl UserRepository for PgUserRepository {
    async fn find_by_email(&self, email: &str) -> ApiResult<Option<DomainUser>> {
        let user = sqlx::query_as::<_, User>(
            "SELECT * FROM users WHERE email = $1 AND is_active = true",
        )
        .bind(email)
        .fetch_optional(&self.pool)
        .await?;

        Ok(user.map(user_to_domain))
    }

    async fn find_by_id(&self, id: Uuid) -> ApiResult<Option<DomainUser>> {
        let user = sqlx::query_as::<_, User>(
            "SELECT * FROM users WHERE id = $1 AND is_active = true",
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(user.map(user_to_domain))
    }

    async fn email_exists(&self, email: &str) -> ApiResult<bool> {
        let exists = sqlx::query_scalar::<_, bool>(
            "SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)",
        )
        .bind(email)
        .fetch_one(&self.pool)
        .await?;

        Ok(exists)
    }

    async fn username_exists(&self, username: &str) -> ApiResult<bool> {
        let exists = sqlx::query_scalar::<_, bool>(
            "SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)",
        )
        .bind(username)
        .fetch_one(&self.pool)
        .await?;

        Ok(exists)
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
        let user = sqlx::query_as::<_, User>(
            r#"
            INSERT INTO users (email, username, password_hash, display_name, grade_level, age, role)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
            "#,
        )
        .bind(email)
        .bind(username)
        .bind(password_hash)
        .bind(display_name)
        .bind(grade_level)
        .bind(age)
        .bind(role)
        .fetch_one(&self.pool)
        .await?;

        Ok(user_to_domain(user))
    }
}
