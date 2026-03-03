# Smart Brain VN API Documentation

**Base URL**: `http://localhost:3000/api/v1`

## Table of Contents
- [Authentication Flow](#authentication-flow)
- [Authentication Endpoints](#authentication-endpoints)
- [User Endpoints](#user-endpoints)
- [Exercise Endpoints](#exercise-endpoints)
- [Progress Endpoints](#progress-endpoints)
- [Achievement Endpoints](#achievement-endpoints)
- [Leaderboard Endpoints](#leaderboard-endpoints)
- [Practice Endpoints (Adaptive)](#practice-endpoints-adaptive)
- [Practice Endpoints (Session-Based)](#practice-endpoints-session-based)
- [Parent Endpoints](#parent-endpoints)
- [XP / Gamification Endpoints](#xp--gamification-endpoints)
- [Health Check](#health-check)
- [WebSocket](#websocket)
- [Error Response Format](#error-response-format)
- [Rate Limiting](#rate-limiting)

---

## Authentication Flow
1. **Register**: New users call `POST /auth/register` to create an account.
2. **Login**: Existing users call `POST /auth/login` with credentials.
3. **Token Usage**: Both successful registration and login return an `access_token` (JWT) and a `refresh_token`.
4. **Authorization**: Include the `access_token` in the `Authorization` header as a Bearer token: `Authorization: Bearer <your_access_token>`.
5. **Refresh**: When the `access_token` expires (15 min), call `POST /auth/refresh` with the `refresh_token` to get a new set of tokens.
6. **Logout**: Call `POST /auth/logout` with the `refresh_token` to invalidate the session.

---

## Authentication Endpoints

### POST /api/v1/auth/register
**Method**: `POST`  
**Path**: `/api/v1/auth/register`  
**Authentication**: No  
**Description**: Creates a new user account.  
**Rate Limit**: 5 requests / minute.

**Request Body**:
```json
{
  "email": "math_wizard_42@example.com",
  "username": "math_wizard_42",
  "password": "SecurePassword123!",
  "display_name": "Alex the Great",
  "grade_level": 4,
  "age": 10,
  "role": "student"
}
```

**Response Body (201 Created)**:
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "math_wizard_42@example.com",
    "username": "math_wizard_42",
    "display_name": "Alex the Great",
    "avatar_url": "https://cdn.example.com/avatars/default.png",
    "grade_level": 4,
    "age": 10,
    "role": "student",
    "is_active": true,
    "created_at": "2023-10-27T10:00:00Z",
    "updated_at": "2023-10-27T10:00:00Z",
    "total_xp": 0,
    "current_level": 1
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "def456..."
}
```

---

### POST /api/v1/auth/login
**Method**: `POST`  
**Path**: `/api/v1/auth/login`  
**Authentication**: No  
**Description**: Authenticates a user and returns tokens.  
**Rate Limit**: 5 requests / minute.

**Request Body**:
```json
{
  "email": "math_wizard_42@example.com",
  "password": "SecurePassword123!"
}
```

**Response Body (200 OK)**:
*(Same structure as Register Response)*

---

### POST /api/v1/auth/refresh
**Method**: `POST`  
**Path**: `/api/v1/auth/refresh`  
**Authentication**: No  
**Description**: Refreshes the access token using a valid refresh token.

**Request Body**:
```json
{
  "refresh_token": "def456..."
}
```

**Response Body (200 OK)**:
*(Same structure as Register Response)*

---

### POST /api/v1/auth/logout
**Method**: `POST`  
**Path**: `/api/v1/auth/logout`  
**Authentication**: No  
**Description**: Invalidates the refresh token and logs out the user.

**Request Body**:
```json
{
  "refresh_token": "def456..."
}
```

**Response Body (200 OK)**:
```json
{
  "message": "Successfully logged out"
}
```

---

## User Endpoints

### GET /api/v1/users/me
**Method**: `GET`  
**Path**: `/api/v1/users/me`  
**Authentication**: Yes  
**Description**: Returns the current authenticated user's profile.

**Headers**:
- `Authorization: Bearer <access_token>`

**Response Body (200 OK)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "math_wizard_42@example.com",
  "username": "math_wizard_42",
  "display_name": "Alex the Great",
  "avatar_url": "https://cdn.example.com/avatars/default.png",
  "grade_level": 4,
  "age": 10,
  "role": "student",
  "is_active": true,
  "created_at": "2023-10-27T10:00:00Z",
  "updated_at": "2023-10-27T10:05:00Z",
  "total_xp": 1250,
  "current_level": 5
}
```

---

### PUT /api/v1/users/me
**Method**: `PUT`  
**Path**: `/api/v1/users/me`  
**Authentication**: Yes  
**Description**: Updates the current user's profile fields.

**Request Body**:
```json
{
  "display_name": "Math Master Alex",
  "avatar_url": "https://cdn.example.com/avatars/new-hero.png",
  "grade_level": 5,
  "age": 11
}
```

**Response Body (200 OK)**:
*(Same structure as User Profile Response)*

---

## Exercise Endpoints

### POST /api/v1/exercises/generate
**Method**: `POST`  
**Path**: `/api/v1/exercises/generate`  
**Authentication**: Yes  
**Description**: Generates a set of exercises based on topic and difficulty.

**Request Body**:
```json
{
  "topic": "multiplication",
  "difficulty": "medium",
  "count": 5
}
```

**Response Body (201 Created)**:
```json
[
  {
    "id": "a1b2c3d4-e5f6-4789-8091-a2b3c4d5e6f7",
    "question_text": "What is 7 x 8?",
    "options": ["48", "54", "56", "64"],
    "difficulty": "medium",
    "topic": "multiplication"
  },
  {
    "id": "b2c3d4e5-f6g7-4890-9101-b3c4d5e6f7g8",
    "question_text": "12 x 4 = ?",
    "options": ["44", "48", "52", "36"],
    "difficulty": "medium",
    "topic": "multiplication"
  }
]
```

---

### POST /api/v1/exercises/submit
**Method**: `POST`  
**Path**: `/api/v1/exercises/submit`  
**Authentication**: Yes  
**Description**: Submits an answer for an exercise and returns feedback.

**Request Body**:
```json
{
  "exercise_id": "a1b2c3d4-e5f6-4789-8091-a2b3c4d5e6f7",
  "answer": 56.0,
  "time_taken_ms": 4500
}
```

**Response Body (200 OK)**:
```json
{
  "is_correct": true,
  "correct_answer": 56.0,
  "points_earned": 15,
  "explanation": "7 times 8 is 56 because 7 x 7 = 49 and adding one more 7 equals 56."
}
```

---

### GET /api/v1/exercises/history
**Method**: `GET`  
**Path**: `/api/v1/exercises/history`  
**Authentication**: Yes  
**Description**: Retrieves a paginated list of previously completed exercises.

**Query Parameters**:
- `page`: 1 (default)
- `per_page`: 20 (default, max 100)

**Response Body (200 OK)**:
```json
{
  "data": [
    {
      "id": "a1b2c3d4-e5f6-4789-8091-a2b3c4d5e6f7",
      "topic": "multiplication",
      "difficulty": "medium",
      "is_correct": true,
      "points_earned": 15,
      "created_at": "2023-10-27T10:15:00Z"
    }
  ],
  "total": 45,
  "page": 1,
  "per_page": 20
}
```

---

## Progress Endpoints

### GET /api/v1/progress/summary
**Method**: `GET`  
**Path**: `/api/v1/progress/summary`  
**Authentication**: Yes  
**Description**: Returns an overview of the user's overall progress.

**Response Body (200 OK)**:
```json
{
  "total_points": 2450,
  "current_streak": 5,
  "longest_streak": 12,
  "total_exercises": 150,
  "accuracy_rate": 0.88,
  "level": 8,
  "xp_to_next_level": 550
}
```

---

### GET /api/v1/progress/topic/{topic}
**Method**: `GET`  
**Path**: `/api/v1/progress/topic/addition`  
**Authentication**: Yes  
**Description**: Returns mastery details for a specific topic.

**Response Body (200 OK)**:
```json
{
  "topic": "addition",
  "mastery_score": 92.5,
  "total_answered": 40,
  "correct_count": 37,
  "recent_scores": [true, true, false, true, true]
}
```

---

## Achievement Endpoints

### GET /api/v1/achievements
**Method**: `GET`  
**Path**: `/api/v1/achievements`  
**Authentication**: Yes  
**Description**: Lists all available achievements and their unlock status for the user.

**Response Body (200 OK)**:
```json
[
  {
    "id": "f1a2b3c4-d5e6-4789-8091-c1d2e3f4g5h6",
    "name": "First Steps",
    "description": "Complete your first exercise",
    "emoji": "🌱",
    "reward_points": 50,
    "is_unlocked": true,
    "unlocked_at": "2023-10-20T08:30:00Z"
  },
  {
    "id": "g2b3c4d5-e6f7-4890-9101-d2e3f4g5h6i7",
    "name": "Math Whiz",
    "description": "Get 10 correct answers in a row",
    "emoji": "⚡",
    "reward_points": 200,
    "is_unlocked": false,
    "unlocked_at": null
  }
]
```

---

## Leaderboard Endpoints

### GET /api/v1/leaderboard
**Method**: `GET`  
**Path**: `/api/v1/leaderboard`  
**Authentication**: Yes  
**Description**: Retrieves the global or periodic leaderboard.

**Query Parameters**:
- `period`: "all_time" (default), "daily", "weekly"
- `page`: 1 (default)
- `per_page`: 20 (default, max 100)

**Response Body (200 OK)**:
```json
{
  "entries": [
    {
      "rank": 1,
      "user_id": "990e8400-e29b-41d4-a716-446655441111",
      "username": "super_solver",
      "display_name": "Captain Calculus",
      "total_points": 15400
    },
    {
      "rank": 42,
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "username": "math_wizard_42",
      "display_name": "Alex the Great",
      "total_points": 2450
    }
  ],
  "total_count": 1250,
  "page": 1,
  "per_page": 20,
  "period": "all_time",
  "my_rank": {
    "rank": 42,
    "total_points": 2450
  }
}
```

---

### GET /api/v1/leaderboard/me
**Method**: `GET`  
**Path**: `/api/v1/leaderboard/me`  
**Authentication**: Yes  
**Description**: Gets the current user's rank for a specific period.

**Query Parameters**:
- `period`: "all_time" (default), "daily", "weekly"

**Response Body (200 OK)**:
```json
{
  "rank": 42,
  "total_points": 2450
}
```

---

## Practice Endpoints (Adaptive)

### GET /api/v1/practice/questions
**Method**: `GET`  
**Path**: `/api/v1/practice/questions`  
**Authentication**: Yes  
**Description**: Gets adaptive questions for a topic.

**Query Parameters**:
- `topic`: "addition" (required)
- `count`: 5 (default, 1-20)

**Response Body (200 OK)**:
```json
[
  {
    "id": "e1f2g3h4-i5j6-4k7l-8m9n-o1p2q3r4s5t6",
    "question_text": "What is 125 + 76?",
    "correct_answer": 201.0,
    "options": ["191", "201", "211", "199"],
    "explanation": "Add 70 to 125 to get 195, then add 6 to get 201.",
    "topic": "addition",
    "difficulty_level": 4
  }
]
```

---

### POST /api/v1/practice/submit
**Method**: `POST`  
**Path**: `/api/v1/practice/submit`  
**Authentication**: Yes  
**Description**: Submits an answer in adaptive mode.

**Request Body**:
```json
{
  "question_id": "e1f2g3h4-i5j6-4k7l-8m9n-o1p2q3r4s5t6",
  "topic": "addition",
  "difficulty_level": 4,
  "question_text": "What is 125 + 76?",
  "correct_answer": 201.0,
  "answer": 201.0,
  "time_taken_ms": 3200
}
```

**Response Body (200 OK)**:
```json
{
  "is_correct": true,
  "correct_answer": 201.0,
  "points_earned": 20,
  "explanation": "Correct! 125 + 76 = 201.",
  "new_difficulty": 5,
  "elo_rating": 1250.5,
  "weak_topics": ["division"],
  "streak": 3
}
```

---

## Practice Endpoints (Session-Based)

### POST /api/v1/practice/start
**Method**: `POST`  
**Path**: `/api/v1/practice/start`  
**Authentication**: Yes  
**Description**: Starts a timed practice session.

**Request Body**:
```json
{
  "topic": "subtraction",
  "question_count": 5
}
```

**Response Body (201 Created)**:
```json
{
  "session_id": "s1e2s3s4-i5o6-4n7-8b9e-r1o2u3t4e5p6",
  "topic": "subtraction",
  "difficulty_start": 3,
  "questions": [
    {
      "id": "q1w2e3r4-t5y6-4u7i-8o9p-a1s2d3f4g5h6",
      "question_text": "50 - 12 = ?",
      "correct_answer": 38.0,
      "options": ["36", "38", "42", "48"],
      "explanation": "50 minus 10 is 40, minus 2 is 38.",
      "topic": "subtraction",
      "difficulty_level": 3
    }
  ]
}
```

---

### POST /api/v1/practice/answer
**Method**: `POST`  
**Path**: `/api/v1/practice/answer`  
**Authentication**: Yes  
**Description**: Submits an answer within a session and returns real-time progress.

**Request Body**:
```json
{
  "session_id": "s1e2s3s4-i5o6-4n7-8b9e-r1o2u3t4e5p6",
  "question_id": "q1w2e3r4-t5y6-4u7i-8o9p-a1s2d3f4g5h6",
  "topic": "subtraction",
  "difficulty_level": 3,
  "question_text": "50 - 12 = ?",
  "correct_answer": 38.0,
  "answer": 38.0,
  "time_taken_ms": 2500
}
```

**Response Body (200 OK)**:
```json
{
  "is_correct": true,
  "correct_answer": 38.0,
  "points_earned": 25,
  "combo_count": 2,
  "combo_multiplier": 1.2,
  "max_combo": 2,
  "new_difficulty": 4,
  "elo_rating": 1280.0,
  "streak": 5,
  "weak_topics": [],
  "session_progress": {
    "total_questions": 5,
    "correct_count": 1,
    "total_points": 25,
    "total_time_ms": 2500,
    "accuracy": 1.0
  }
}
```

---

### GET /api/v1/practice/result/{session_id}
**Method**: `GET`  
**Path**: `/api/v1/practice/result/s1e2s3s4-i5o6-4n7-8b9e-r1o2u3t4e5p6`  
**Authentication**: Yes  
**Description**: Retrieves the full result of a completed session.

**Response Body (200 OK)**:
```json
{
  "session_id": "s1e2s3s4-i5o6-4n7-8b9e-r1o2u3t4e5p6",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "topic": "subtraction",
  "status": "completed",
  "total_questions": 5,
  "correct_count": 4,
  "accuracy": 0.8,
  "total_points": 120,
  "total_time_ms": 15400,
  "max_combo": 3,
  "difficulty_start": 3,
  "difficulty_end": 5,
  "started_at": "2023-10-27T11:00:00Z",
  "completed_at": "2023-10-27T11:00:15Z",
  "results": [
    {
      "id": "q1w2e3r4-t5y6-4u7i-8o9p-a1s2d3f4g5h6",
      "question_text": "50 - 12 = ?",
      "correct_answer": 38.0,
      "user_answer": 38.0,
      "is_correct": true,
      "points_earned": 25,
      "combo_count": 2,
      "combo_multiplier": 1.2,
      "time_taken_ms": 2500,
      "created_at": "2023-10-27T11:00:05Z"
    }
  ]
}
```

---

## Parent Endpoints

### GET /api/v1/parent/children
**Method**: `GET`  
**Path**: `/api/v1/parent/children`  
**Authentication**: Yes (Parent role)  
**Description**: Lists all children linked to the parent account.

**Response Body (200 OK)**:
```json
[
  {
    "child_id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "math_wizard_42",
    "display_name": "Alex the Great",
    "grade_level": 4,
    "total_points": 2450,
    "total_exercises": 150,
    "current_streak": 5
  }
]
```

---

### GET /api/v1/parent/child/{child_id}/progress
**Method**: `GET`  
**Path**: `/api/v1/parent/child/550e8400-e29b-41d4-a716-446655440000/progress`  
**Authentication**: Yes (Parent role)  
**Description**: Detailed progress report for a specific child.

**Response Body (200 OK)**:
```json
{
  "child": {
    "child_id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "math_wizard_42",
    "display_name": "Alex the Great",
    "grade_level": 4,
    "total_points": 2450,
    "total_exercises": 150,
    "current_streak": 5
  },
  "topic_mastery": [
    {
      "topic": "addition",
      "mastery_score": 92.5,
      "total_answered": 40,
      "correct_count": 37,
      "recent_scores": [true, true, false, true, true]
    }
  ],
  "daily_goal": {
    "daily_exercise_target": 10,
    "daily_time_target_minutes": 30,
    "active_topics": ["addition", "subtraction"]
  },
  "recent_activity": [
    {
      "id": "a1b2c3d4-e5f6-4789-8091-a2b3c4d5e6f7",
      "topic": "addition",
      "difficulty": "easy",
      "is_correct": true,
      "points_earned": 10,
      "created_at": "2023-10-27T09:45:00Z"
    }
  ]
}
```

---

### PUT /api/v1/parent/child/{child_id}/goals
**Method**: `PUT`  
**Path**: `/api/v1/parent/child/550e8400-e29b-41d4-a716-446655440000/goals`  
**Authentication**: Yes (Parent role)  
**Description**: Updates learning goals for a child.

**Request Body**:
```json
{
  "daily_exercise_target": 15,
  "daily_time_target_minutes": 45,
  "active_topics": ["addition", "subtraction", "multiplication"]
}
```

**Response Body (200 OK)**:
```json
{
  "message": "Goals updated successfully",
  "daily_exercise_target": 15,
  "daily_time_target_minutes": 45,
  "active_topics": ["addition", "subtraction", "multiplication"]
}
```

---

## XP / Gamification Endpoints

### GET /api/v1/xp/profile
**Method**: `GET`  
**Path**: `/api/v1/xp/profile`  
**Authentication**: Yes  
**Description**: Returns the user's gamification profile.

**Response Body (200 OK)**:
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "total_xp": 12450,
  "current_level": 12,
  "xp_in_current_level": 450,
  "xp_for_next_level": 1000,
  "xp_progress_percent": 45.0,
  "unlocked_achievements": [
    {
      "id": "f1a2b3c4-d5e6-4789-8091-c1d2e3f4g5h6",
      "name": "First Steps",
      "description": "Complete your first exercise",
      "emoji": "🌱",
      "reward_points": 50,
      "unlocked_at": "2023-10-20T08:30:00Z"
    }
  ],
  "active_theme": {
    "id": "t1h2e3m4-e5f6-4789-8091-v1c2b3n4m5a6",
    "name": "Space Explorer",
    "description": "A cosmic theme for math travelers",
    "emoji": "🚀"
  }
}
```

---

### GET /api/v1/xp/themes
**Method**: `GET`  
**Path**: `/api/v1/xp/themes`  
**Authentication**: Yes  
**Description**: Lists all available themes and their unlock status.

**Response Body (200 OK)**:
```json
{
  "themes": [
    {
      "id": "t1h2e3m4-e5f6-4789-8091-v1c2b3n4m5a6",
      "name": "Space Explorer",
      "description": "A cosmic theme for math travelers",
      "emoji": "🚀",
      "required_level": 5,
      "required_xp": 5000,
      "is_premium": false,
      "is_unlocked": true,
      "is_active": true,
      "can_unlock": false
    },
    {
      "id": "u2i3o4p5-f6g7-4890-9101-w2x3y4z5a6b7",
      "name": "Deep Sea",
      "description": "Dive deep into numbers",
      "emoji": "🌊",
      "required_level": 15,
      "required_xp": 20000,
      "is_premium": true,
      "is_unlocked": false,
      "is_active": false,
      "can_unlock": false
    }
  ],
  "active_theme_id": "t1h2e3m4-e5f6-4789-8091-v1c2b3n4m5a6"
}
```

---

### POST /api/v1/xp/themes/{id}/unlock
**Method**: `POST`  
**Path**: `/api/v1/xp/themes/u2i3o4p5-f6g7-4890-9101-w2x3y4z5a6b7/unlock`  
**Authentication**: Yes  
**Description**: Unlocks a theme if requirements are met.

**Response Body (200 OK)**:
```json
{
  "id": "u2i3o4p5-f6g7-4890-9101-w2x3y4z5a6b7",
  "name": "Deep Sea",
  "description": "Dive deep into numbers",
  "emoji": "🌊"
}
```

---

### PUT /api/v1/xp/themes/{id}/activate
**Method**: `PUT`  
**Path**: `/api/v1/xp/themes/u2i3o4p5-f6g7-4890-9101-w2x3y4z5a6b7/activate`  
**Authentication**: Yes  
**Description**: Sets a theme as active for the user.

**Response Body (200 OK)**:
```json
{
  "message": "Theme activated successfully"
}
```

---

## Health Check

### GET /api/v1/health
**Method**: `GET`  
**Path**: `/api/v1/health`  
**Authentication**: No  
**Description**: Returns service health status and version information.

**Response Body (200 OK)**:
```json
{
  "status": "healthy",
  "version": "1.2.0",
  "db_connected": true,
  "redis_connected": true
}
```

---

## WebSocket

### GET /ws
**Method**: `GET` (Upgrade)  
**Path**: `/ws?token=<JWT>`  
**Authentication**: Yes (via query token)  
**Description**: Real-time notification channel for user events.

**Events Emitted**:
- `achievement_unlocked`: `{ "achievement_id": "UUID", "name": "string" }`
- `streak_update`: `{ "current_streak": 5, "is_milestone": true }`
- `score_update`: `{ "total_points": 2450, "delta": 15 }`

---

## Error Response Format
All error responses follow this JSON structure:

```json
{
  "error": "error_code",
  "message": "Human-readable explanation of what went wrong."
}
```

### Common Error Codes
| HTTP Code | Error Code | Description |
|-----------|------------|-------------|
| 400 | `bad_request` | The request was malformed or had invalid parameters. |
| 401 | `unauthorized` | Authentication is required or token is invalid/expired. |
| 403 | `forbidden` | You do not have permission to access this resource. |
| 404 | `not_found` | The requested resource does not exist. |
| 409 | `conflict` | The request conflicts with current state (e.g., email already exists). |
| 422 | `validation_error` | Data failed business logic validation. |
| 500 | `internal_error` | An unexpected error occurred on the server. |

---

## Rate Limiting
To ensure service stability, the following rate limits apply:
- **Authentication Endpoints**: 5 requests per minute per IP.
- **General API Endpoints**: 60 requests per minute per user.
- **WebSocket Connections**: 1 active connection per user account.
