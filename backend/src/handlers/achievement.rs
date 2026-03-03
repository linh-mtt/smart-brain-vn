use axum::extract::State;
use axum::Json;
use sqlx::PgPool;

use crate::auth::extractor::AuthUser;
use crate::error::ApiResult;
use crate::models::user::AchievementResponse;
use crate::error::ErrorResponse;

#[utoipa::path(get, path = "/api/v1/achievements", tag = "Achievements", responses((status = 200, description = "List of achievements", body = Vec<AchievementResponse>), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
pub async fn list_achievements(
    auth: AuthUser,
    State(pool): State<PgPool>,
) -> ApiResult<Json<Vec<AchievementResponse>>> {
    let achievements = sqlx::query_as::<_, AchievementResponse>(
        r#"
        SELECT
            a.id,
            a.name,
            a.description,
            a.emoji,
            a.reward_points,
            CASE WHEN ua.id IS NOT NULL THEN true ELSE false END as is_unlocked,
            ua.unlocked_at
        FROM achievements a
        LEFT JOIN user_achievements ua ON a.id = ua.achievement_id AND ua.user_id = $1
        ORDER BY a.name
        "#,
    )
    .bind(auth.user_id)
    .fetch_all(&pool)
    .await?;

    Ok(Json(achievements))
}
