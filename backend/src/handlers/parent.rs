use axum::extract::{Path, State};
use axum::Json;
use sqlx::PgPool;
use uuid::Uuid;
use validator::Validate;

use crate::auth::extractor::AuthUser;
use crate::error::{ApiError, ApiResult};
use crate::models::user::{
    ChildProgress, ChildSummary, DailyGoalResponse, RecentExercise, TopicProgressResponse,
    UpdateGoalsRequest, UserRole,
};

fn require_parent(auth: &AuthUser) -> ApiResult<()> {
    if auth.role != UserRole::Parent && auth.role != UserRole::Admin {
        return Err(ApiError::Forbidden);
    }
    Ok(())
}

pub async fn list_children(
    auth: AuthUser,
    State(pool): State<PgPool>,
) -> ApiResult<Json<Vec<ChildSummary>>> {
    require_parent(&auth)?;

    let children = sqlx::query_as::<_, (Uuid, String, Option<String>, i32)>(
        r#"
        SELECT u.id, u.username, u.display_name, u.grade_level
        FROM parent_child_links pcl
        JOIN users u ON pcl.child_id = u.id
        WHERE pcl.parent_id = $1 AND u.is_active = true
        "#,
    )
    .bind(auth.user_id)
    .fetch_all(&pool)
    .await?;

    let mut result = Vec::new();
    for (child_id, username, display_name, grade_level) in children {
        let total_points: i64 = sqlx::query_scalar(
            "SELECT COALESCE(SUM(points_earned), 0) FROM exercise_results WHERE user_id = $1",
        )
        .bind(child_id)
        .fetch_one(&pool)
        .await?;

        let total_exercises: i64 =
            sqlx::query_scalar("SELECT COUNT(*) FROM exercise_results WHERE user_id = $1")
                .bind(child_id)
                .fetch_one(&pool)
                .await?;

        let current_streak: i32 = sqlx::query_scalar(
            "SELECT COALESCE(MAX(streak_count), 0) FROM daily_progress WHERE user_id = $1",
        )
        .bind(child_id)
        .fetch_one(&pool)
        .await
        .unwrap_or(0);

        result.push(ChildSummary {
            child_id,
            username,
            display_name,
            grade_level,
            total_points,
            total_exercises,
            current_streak,
        });
    }

    Ok(Json(result))
}

pub async fn child_progress(
    auth: AuthUser,
    State(pool): State<PgPool>,
    Path(child_id): Path<Uuid>,
) -> ApiResult<Json<ChildProgress>> {
    require_parent(&auth)?;

    // Verify parent-child relationship
    let linked: bool = sqlx::query_scalar(
        "SELECT EXISTS(SELECT 1 FROM parent_child_links WHERE parent_id = $1 AND child_id = $2)",
    )
    .bind(auth.user_id)
    .bind(child_id)
    .fetch_one(&pool)
    .await?;

    if !linked {
        return Err(ApiError::Forbidden);
    }

    // Get child info
    let child_info = sqlx::query_as::<_, (String, Option<String>, i32)>(
        "SELECT username, display_name, grade_level FROM users WHERE id = $1",
    )
    .bind(child_id)
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| ApiError::NotFound("Child not found".to_string()))?;

    let total_points: i64 = sqlx::query_scalar(
        "SELECT COALESCE(SUM(points_earned), 0) FROM exercise_results WHERE user_id = $1",
    )
    .bind(child_id)
    .fetch_one(&pool)
    .await?;

    let total_exercises: i64 =
        sqlx::query_scalar("SELECT COUNT(*) FROM exercise_results WHERE user_id = $1")
            .bind(child_id)
            .fetch_one(&pool)
            .await?;

    let current_streak: i32 = sqlx::query_scalar(
        "SELECT COALESCE(MAX(streak_count), 0) FROM daily_progress WHERE user_id = $1",
    )
    .bind(child_id)
    .fetch_one(&pool)
    .await
    .unwrap_or(0);

    let child_summary = ChildSummary {
        child_id,
        username: child_info.0,
        display_name: child_info.1,
        grade_level: child_info.2,
        total_points,
        total_exercises,
        current_streak,
    };

    // Get topic mastery
    let mastery_rows = sqlx::query_as::<_, (String, i32, i32, f64)>(
        r#"
        SELECT topic, total_answered, correct_count, mastery_score
        FROM topic_mastery
        WHERE user_id = $1
        "#,
    )
    .bind(child_id)
    .fetch_all(&pool)
    .await?;

    let topic_mastery: Vec<TopicProgressResponse> = mastery_rows
        .into_iter()
        .map(|(topic, total_answered, correct_count, mastery_score)| TopicProgressResponse {
            topic,
            mastery_score,
            total_answered,
            correct_count,
            recent_scores: Vec::new(),
        })
        .collect();

    // Get daily goal
    let daily_goal = sqlx::query_as::<_, DailyGoalResponse>(
        r#"
        SELECT daily_exercise_target, daily_time_target_minutes, active_topics
        FROM daily_goals
        WHERE parent_id = $1 AND child_id = $2
        "#,
    )
    .bind(auth.user_id)
    .bind(child_id)
    .fetch_optional(&pool)
    .await?;

    // Recent activity
    let recent_activity = sqlx::query_as::<_, RecentExercise>(
        r#"
        SELECT id, topic, difficulty, is_correct, points_earned, created_at
        FROM exercise_results
        WHERE user_id = $1
        ORDER BY created_at DESC
        LIMIT 20
        "#,
    )
    .bind(child_id)
    .fetch_all(&pool)
    .await?;

    Ok(Json(ChildProgress {
        child: child_summary,
        topic_mastery,
        daily_goal,
        recent_activity,
    }))
}

pub async fn update_goals(
    auth: AuthUser,
    State(pool): State<PgPool>,
    Path(child_id): Path<Uuid>,
    Json(body): Json<UpdateGoalsRequest>,
) -> ApiResult<Json<serde_json::Value>> {
    require_parent(&auth)?;

    body.validate()
        .map_err(|e| ApiError::ValidationError(e.to_string()))?;

    // Verify parent-child relationship
    let linked: bool = sqlx::query_scalar(
        "SELECT EXISTS(SELECT 1 FROM parent_child_links WHERE parent_id = $1 AND child_id = $2)",
    )
    .bind(auth.user_id)
    .bind(child_id)
    .fetch_one(&pool)
    .await?;

    if !linked {
        return Err(ApiError::Forbidden);
    }

    let exercise_target = body.daily_exercise_target.unwrap_or(10);
    let time_target = body.daily_time_target_minutes.unwrap_or(15);
    let topics = body
        .active_topics
        .as_ref()
        .map(|t| serde_json::json!(t))
        .unwrap_or_else(|| serde_json::json!(["addition", "subtraction"]));

    sqlx::query(
        r#"
        INSERT INTO daily_goals (parent_id, child_id, daily_exercise_target, daily_time_target_minutes, active_topics)
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT (parent_id, child_id)
        DO UPDATE SET
            daily_exercise_target = $3,
            daily_time_target_minutes = $4,
            active_topics = $5,
            updated_at = NOW()
        "#,
    )
    .bind(auth.user_id)
    .bind(child_id)
    .bind(exercise_target)
    .bind(time_target)
    .bind(&topics)
    .execute(&pool)
    .await?;

    tracing::info!(
        "Goals updated for child {} by parent {}",
        child_id,
        auth.user_id
    );

    Ok(Json(serde_json::json!({
        "message": "Goals updated successfully",
        "daily_exercise_target": exercise_target,
        "daily_time_target_minutes": time_target,
        "active_topics": topics,
    })))
}
