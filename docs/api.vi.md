# Tài liệu API Smart Brain VN

**Base URL**: `http://localhost:3000/api/v1`

## Mục lục
- [Quy trình xác thực](#authentication-flow)
- [Các Endpoint xác thực](#authentication-endpoints)
- [Các Endpoint người dùng](#user-endpoints)
- [Các Endpoint bài tập](#exercise-endpoints)
- [Các Endpoint tiến độ](#progress-endpoints)
- [Các Endpoint thành tựu](#achievement-endpoints)
- [Các Endpoint bảng xếp hạng](#leaderboard-endpoints)
- [Các Endpoint luyện tập (Thích ứng)](#practice-endpoints-adaptive)
- [Các Endpoint luyện tập (Theo phiên)](#practice-endpoints-session-based)
- [Các Endpoint cho phụ huynh](#parent-endpoints)
- [Các Endpoint XP / Game hóa](#xp--gamification-endpoints)
- [Kiểm tra trạng thái hệ thống](#health-check)
- [WebSocket](#websocket)
- [Định dạng phản hồi lỗi](#error-response-format)
- [Giới hạn tốc độ](#rate-limiting)

---

## Quy trình xác thực
1. **Đăng ký**: Người dùng mới gọi `POST /auth/register` để tạo tài khoản.
2. **Đăng nhập**: Người dùng đã có tài khoản gọi `POST /auth/login` với thông tin đăng nhập.
3. **Sử dụng Token**: Cả đăng ký và đăng nhập thành công đều trả về một `access_token` (JWT) và một `refresh_token`.
4. **Ủy quyền**: Đính kèm `access_token` trong header `Authorization` dưới dạng Bearer token: `Authorization: Bearer <your_access_token>`.
5. **Làm mới**: Khi `access_token` hết hạn (15 phút), gọi `POST /auth/refresh` với `refresh_token` để nhận bộ token mới.
6. **Đăng xuất**: Gọi `POST /auth/logout` với `refresh_token` để hủy phiên làm việc.

---

## Các Endpoint xác thực

### POST /api/v1/auth/register
**Method**: `POST`  
**Path**: `/api/v1/auth/register`  
**Authentication**: No  
**Description**: Tạo tài khoản người dùng mới.  
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
**Description**: Xác thực người dùng và trả về các token.  
**Rate Limit**: 5 requests / minute.

**Request Body**:
```json
{
  "email": "math_wizard_42@example.com",
  "password": "SecurePassword123!"
}
```

**Response Body (200 OK)**:
*(Cấu trúc tương tự như phản hồi Đăng ký)*

---

### POST /api/v1/auth/refresh
**Method**: `POST`  
**Path**: `/api/v1/auth/refresh`  
**Authentication**: No  
**Description**: Làm mới access token bằng refresh token hợp lệ.

**Request Body**:
```json
{
  "refresh_token": "def456..."
}
```

**Response Body (200 OK)**:
*(Cấu trúc tương tự như phản hồi Đăng ký)*

---

### POST /api/v1/auth/logout
**Method**: `POST`  
**Path**: `/api/v1/auth/logout`  
**Authentication**: No  
**Description**: Hủy refresh token và đăng xuất người dùng.

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

## Các Endpoint người dùng

### GET /api/v1/users/me
**Method**: `GET`  
**Path**: `/api/v1/users/me`  
**Authentication**: Yes  
**Description**: Trả về hồ sơ của người dùng hiện tại đã được xác thực.

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
**Description**: Cập nhật các trường hồ sơ của người dùng hiện tại.

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
*(Cấu trúc tương tự như phản hồi Hồ sơ người dùng)*

---

## Các Endpoint bài tập

### POST /api/v1/exercises/generate
**Method**: `POST`  
**Path**: `/api/v1/exercises/generate`  
**Authentication**: Yes  
**Description**: Tạo một bộ bài tập dựa trên chủ đề và độ khó.

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
**Description**: Gửi câu trả lời cho một bài tập và trả về phản hồi.

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
**Description**: Lấy danh sách phân trang các bài tập đã hoàn thành trước đó.

**Query Parameters**:
- `page`: 1 (mặc định)
- `per_page`: 20 (mặc định, tối đa 100)

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

## Các Endpoint tiến độ

### GET /api/v1/progress/summary
**Method**: `GET`  
**Path**: `/api/v1/progress/summary`  
**Authentication**: Yes  
**Description**: Trả về cái nhìn tổng quan về tiến độ tổng thể của người dùng.

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
**Description**: Trả về chi tiết mức độ thành thạo cho một chủ đề cụ thể.

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

## Các Endpoint thành tựu

### GET /api/v1/achievements
**Method**: `GET`  
**Path**: `/api/v1/achievements`  
**Authentication**: Yes  
**Description**: Liệt kê tất cả các thành tựu hiện có và trạng thái mở khóa của người dùng.

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

## Các Endpoint bảng xếp hạng

### GET /api/v1/leaderboard
**Method**: `GET`  
**Path**: `/api/v1/leaderboard`  
**Authentication**: Yes  
**Description**: Lấy bảng xếp hạng toàn cầu hoặc theo định kỳ.

**Query Parameters**:
- `period`: "all_time" (mặc định), "daily", "weekly"
- `page`: 1 (mặc định)
- `per_page`: 20 (mặc định, tối đa 100)

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
**Description**: Lấy thứ hạng của người dùng hiện tại trong một khoảng thời gian cụ thể.

**Query Parameters**:
- `period`: "all_time" (mặc định), "daily", "weekly"

**Response Body (200 OK)**:
```json
{
  "rank": 42,
  "total_points": 2450
}
```

---

## Các Endpoint luyện tập (Thích ứng)

### GET /api/v1/practice/questions
**Method**: `GET`  
**Path**: `/api/v1/practice/questions`  
**Authentication**: Yes  
**Description**: Lấy các câu hỏi thích ứng cho một chủ đề.

**Query Parameters**:
- `topic`: "addition" (bắt buộc)
- `count`: 5 (mặc định, 1-20)

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
**Description**: Gửi câu trả lời trong chế độ thích ứng.

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

## Các Endpoint luyện tập (Theo phiên)

### POST /api/v1/practice/start
**Method**: `POST`  
**Path**: `/api/v1/practice/start`  
**Authentication**: Yes  
**Description**: Bắt đầu một phiên luyện tập có tính giờ.

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
**Description**: Gửi câu trả lời trong một phiên và trả về tiến độ thời gian thực.

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
**Description**: Lấy toàn bộ kết quả của một phiên đã hoàn thành.

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

## Các Endpoint cho phụ huynh

### GET /api/v1/parent/children
**Method**: `GET`  
**Path**: `/api/v1/parent/children`  
**Authentication**: Yes (Parent role)  
**Description**: Liệt kê tất cả trẻ em được liên kết với tài khoản phụ huynh.

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
**Description**: Báo cáo tiến độ chi tiết cho một đứa trẻ cụ thể.

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
**Description**: Cập nhật mục tiêu học tập cho trẻ.

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

## Các Endpoint XP / Game hóa

### GET /api/v1/xp/profile
**Method**: `GET`  
**Path**: `/api/v1/xp/profile`  
**Authentication**: Yes  
**Description**: Trả về hồ sơ game hóa của người dùng.

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
**Description**: Liệt kê tất cả các chủ đề hiện có và trạng thái mở khóa của chúng.

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
**Description**: Mở khóa một chủ đề nếu các yêu cầu được đáp ứng.

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
**Description**: Thiết lập một chủ đề làm chủ đề hoạt động cho người dùng.

**Response Body (200 OK)**:
```json
{
  "message": "Theme activated successfully"
}
```

---

## Kiểm tra trạng thái hệ thống

### GET /api/v1/health
**Method**: `GET`  
**Path**: `/api/v1/health`  
**Authentication**: No  
**Description**: Trả về trạng thái hoạt động của dịch vụ và thông tin phiên bản.

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
**Authentication**: Yes (qua query token)  
**Description**: Kênh thông báo thời gian thực cho các sự kiện của người dùng.

**Events Emitted**:
- `achievement_unlocked`: `{ "achievement_id": "UUID", "name": "string" }`
- `streak_update`: `{ "current_streak": 5, "is_milestone": true }`
- `score_update`: `{ "total_points": 2450, "delta": 15 }`

---

## Định dạng phản hồi lỗi
Tất cả các phản hồi lỗi đều tuân theo cấu trúc JSON này:

```json
{
  "error": "error_code",
  "message": "Human-readable explanation of what went wrong."
}
```

### Các mã lỗi phổ biến
| HTTP Code | Error Code | Mô tả |
|-----------|------------|-------------|
| 400 | `bad_request` | Yêu cầu bị sai định dạng hoặc có tham số không hợp lệ. |
| 401 | `unauthorized` | Yêu cầu xác thực hoặc token không hợp lệ/hết hạn. |
| 403 | `forbidden` | Bạn không có quyền truy cập tài nguyên này. |
| 404 | `not_found` | Tài nguyên được yêu cầu không tồn tại. |
| 409 | `conflict` | Yêu cầu xung đột với trạng thái hiện tại (ví dụ: email đã tồn tại). |
| 422 | `validation_error` | Dữ liệu không vượt qua kiểm tra logic nghiệp vụ. |
| 500 | `internal_error` | Đã xảy ra lỗi không mong muốn trên máy chủ. |

---

## Giới hạn tốc độ
Để đảm bảo tính ổn định của dịch vụ, các giới hạn tốc độ sau đây được áp dụng:
- **Các Endpoint xác thực**: 5 yêu cầu mỗi phút cho mỗi IP.
- **Các Endpoint API chung**: 60 yêu cầu mỗi phút cho mỗi người dùng.
- **Kết nối WebSocket**: 1 kết nối đang hoạt động cho mỗi tài khoản người dùng.
