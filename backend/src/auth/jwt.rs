use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};

use crate::config::Config;
use crate::error::ApiResult;
use crate::models::user::{TokenClaims, User};

pub fn create_access_token(user: &User, config: &Config) -> ApiResult<String> {
    let now = chrono::Utc::now();
    let expires_at = now + config.jwt_access_expires_in;

    let claims = TokenClaims {
        sub: user.id.to_string(),
        email: user.email.clone(),
        role: user.role.to_string(),
        exp: expires_at.timestamp() as usize,
        iat: now.timestamp() as usize,
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(config.jwt_secret.as_bytes()),
    )?;

    Ok(token)
}

pub fn create_refresh_token(user: &User, config: &Config) -> ApiResult<String> {
    let now = chrono::Utc::now();
    let expires_at = now + config.jwt_refresh_expires_in;

    let claims = TokenClaims {
        sub: user.id.to_string(),
        email: user.email.clone(),
        role: user.role.to_string(),
        exp: expires_at.timestamp() as usize,
        iat: now.timestamp() as usize,
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(config.jwt_secret.as_bytes()),
    )?;

    Ok(token)
}

pub fn decode_token(token: &str, secret: &str) -> ApiResult<TokenClaims> {
    let token_data = decode::<TokenClaims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )?;

    Ok(token_data.claims)
}
