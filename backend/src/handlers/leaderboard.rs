use axum::extract::{Query, State};
use axum::Json;
use sqlx::PgPool;

use crate::auth::extractor::AuthUser;
use crate::error::ApiResult;
use crate::models::user::{LeaderboardEntry, LeaderboardQuery};

pub async fn get_leaderboard(
    _auth: AuthUser,
    State(pool): State<PgPool>,
    Query(params): Query<LeaderboardQuery>,
) -> ApiResult<Json<Vec<LeaderboardEntry>>> {
    let period = params.period.unwrap_or_else(|| "all_time".to_string());

    let entries = sqlx::query_as::<_, LeaderboardEntry>(
        r#"
        SELECT
            le.user_id,
            u.username,
            u.display_name,
            le.total_points::int8,
            ROW_NUMBER() OVER (ORDER BY le.total_points DESC)::int8 as rank
        FROM leaderboard_entries le
        JOIN users u ON le.user_id = u.id
        WHERE le.period = $1 AND u.is_active = true
        ORDER BY le.total_points DESC
        LIMIT 50
        "#,
    )
    .bind(&period)
    .fetch_all(&pool)
    .await?;

    Ok(Json(entries))
}
