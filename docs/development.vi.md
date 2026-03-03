# SmartMath Kids — Hướng dẫn cho Nhà phát triển (Developer Onboarding Guide)

Chào mừng bạn đến với dự án SmartMath Kids! Hướng dẫn này sẽ giúp bạn từ con số không trở thành một nhà phát triển làm việc hiệu quả trong vòng chưa đầy 30 phút.

---

## Mục lục

1. [Điều kiện tiên quyết](#1-dieu-kien-tien-quyet)
2. [Thiết lập Repository](#2-thiet-lap-repository)
3. [Cấu hình môi trường](#3-cau-hinh-moi-truong)
4. [Chạy với Docker (Khuyên dùng)](#4-chay-voi-docker-khuyen-dung)
5. [Chạy cục bộ (Không dùng Docker)](#5-chay-cuc-bo-khong-dung-docker)
6. [Cấu trúc dự án](#6-cau-truc-du-an)
7. [Quy ước lập trình](#7-quy-uoc-lap-trinh)
8. [Chiến lược nhánh (Branch Strategy)](#8-chien-luoc-nhanh-branch-strategy)
9. [Luồng công việc phát triển (Development Workflow)](#9-luong-cong-viec-phat-trien-development-workflow)
10. [Kiểm thử (Testing)](#10-kiem-thu-testing)
11. [Các tác vụ thường gặp](#11-cac-tac-vu-thuong-gap)
12. [Xử lý sự cố (Troubleshooting)](#12-xu-ly-su-co-troubleshooting)

---

## 1. Điều kiện tiên quyết

### Bắt buộc

| Công cụ | Phiên bản | Kiểm tra | Cài đặt |
|---|---|---|---|
| **Git** | 2.x+ | `git --version` | [git-scm.com](https://git-scm.com/) |
| **Docker** | 24+ | `docker --version` | [docker.com](https://docs.docker.com/get-docker/) |
| **Docker Compose** | v2+ | `docker compose version` | Đã bao gồm trong Docker Desktop |

### Để phát triển cục bộ (Tùy chọn)

| Công cụ | Phiên bản | Kiểm tra | Cài đặt |
|---|---|---|---|
| **Rust** | 1.88+ | `rustc --version` | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh` |
| **Flutter** | 3.29.3 | `flutter --version` | [flutter.dev](https://docs.flutter.dev/get-started/install) |
| **PostgreSQL** | 16 | `psql --version` | [postgresql.org](https://www.postgresql.org/download/) |
| **sqlx-cli** | 0.8 | `sqlx --version` | `cargo install sqlx-cli --no-default-features --features rustls,postgres` |

---

## 2. Thiết lập Repository

```bash
# Clone repository
git clone https://github.com/your-org/smart-brain-vn.git
cd smart-brain-vn

# Kiểm tra cấu trúc dự án
ls -la
# Kết quả mong đợi: backend/  frontend/  docker-compose.yml  .env.example  docs/
```

---

## 3. Cấu hình môi trường

```bash
# Sao chép mẫu tệp môi trường
cp .env.example .env

# Xem và tùy chỉnh (các giá trị mặc định phù hợp cho phát triển)
cat .env
```

### Biến môi trường

| Biến | Mặc định | Mô tả |
|---|---|---|
| `POSTGRES_USER` | `smartmath` | Tên người dùng PostgreSQL |
| `POSTGRES_PASSWORD` | `smartmath_dev_pass` | Mật khẩu PostgreSQL |
| `POSTGRES_DB` | `smartmath` | Tên cơ sở dữ liệu |
| `POSTGRES_PORT` | `5432` | Cổng PostgreSQL |
| `REDIS_PASSWORD` | `smartmath_redis_dev` | Mật khẩu DragonflyDB |
| `REDIS_PORT` | `6379` | Cổng DragonflyDB |
| `BACKEND_PORT` | `3000` | Cổng Backend API |
| `JWT_SECRET` | (dev secret) | Khóa ký JWT (**thay đổi khi deploy production**) |
| `JWT_ACCESS_TOKEN_EXPIRES_IN` | `15m` | Thời gian sống (TTL) của Access token |
| `JWT_REFRESH_TOKEN_EXPIRES_IN` | `7d` | Thời gian sống (TTL) của Refresh token |
| `RUST_LOG` | `info,smartmath_backend=debug` | Bộ lọc cấp độ log |
| `ENVIRONMENT` | `development` | Môi trường thực thi |
| `FRONTEND_PORT` | `8080` | Cổng Frontend web |
| `API_BASE_URL` | `http://localhost:3000/api/v1` | URL API cơ bản cho frontend |
| `WS_URL` | `ws://localhost:3000/ws` | URL WebSocket cho frontend |

> **Bảo mật**: Không bao giờ commit các tệp `.env`. Tệp `.env.example` chỉ chứa các giá trị mặc định an toàn.

---

## 4. Chạy với Docker (Khuyên dùng)

Cách nhanh nhất để chạy toàn bộ hệ thống.

### Bắt đầu mọi thứ

```bash
# Build và chạy tất cả dịch vụ
docker compose up --build -d

# Xem logs
docker compose logs -f
```

### Xác minh các dịch vụ

```bash
# Kiểm tra các container đang chạy
docker compose ps

# Kết quả mong đợi:
# NAME                  STATUS        PORTS
# smartmath-postgres    Up (healthy)  0.0.0.0:5432->5432/tcp
# smartmath-dragonfly   Up (healthy)  0.0.0.0:6379->6379/tcp
# smartmath-backend     Up (healthy)  0.0.0.0:3000->3000/tcp
# smartmath-frontend    Up            0.0.0.0:8080->80/tcp

# Kiểm tra sức khỏe (health) của backend
curl http://localhost:3000/api/v1/health
# Mong đợi: {"status":"healthy","db_connected":true,"redis_connected":true,...}

# Mở frontend
open http://localhost:8080
```

### URL của các dịch vụ

| Dịch vụ | URL | Mục đích |
|---|---|---|
| **Frontend** | http://localhost:8080 | Ứng dụng web Flutter |
| **Backend API** | http://localhost:3000/api/v1 | REST API |
| **WebSocket** | ws://localhost:3000/ws | Các sự kiện thời gian thực |
| **Swagger Docs** | http://localhost:3000/docs/backend-apis | Tài liệu API |
| **PostgreSQL** | localhost:5432 | Cơ sở dữ liệu (kết nối bằng `psql`) |
| **DragonflyDB** | localhost:6379 | Cache (kết nối bằng `redis-cli`) |

### Các lệnh Docker thường dùng

```bash
# Dừng tất cả dịch vụ
docker compose down

# Dừng và xóa volumes (bắt đầu lại hoàn toàn mới)
docker compose down -v

# Build lại một dịch vụ cụ thể
docker compose build backend
docker compose up -d backend

# Xem log cho một dịch vụ cụ thể
docker compose logs -f backend

# Thực thi lệnh bên trong container
docker compose exec backend sh
docker compose exec postgres psql -U smartmath -d smartmath
```

---

## 5. Chạy cục bộ (Không dùng Docker)

### 5.1 Khởi động hạ tầng

```bash
# Chỉ chạy PostgreSQL và DragonflyDB qua Docker
docker compose up -d postgres dragonfly
```

### 5.2 Backend

```bash
cd backend

# Copy env (nếu chưa thực hiện ở thư mục gốc)
export DATABASE_URL="postgres://smartmath:smartmath_dev_pass@localhost:5432/smartmath"
export REDIS_URL="redis://default:smartmath_redis_dev@localhost:6379"
export JWT_SECRET="dev_jwt_secret_change_in_production_minimum_32_chars"
export RUST_LOG="info,smartmath_backend=debug"

# Chạy migrations cho cơ sở dữ liệu
cargo install sqlx-cli --no-default-features --features rustls,postgres
sqlx migrate run

# Chạy backend ở chế độ phát triển
cargo run

# Hoặc với tự động tải lại (cài đặt cargo-watch trước)
cargo install cargo-watch
cargo watch -x run
```

### 5.3 Frontend

```bash
cd frontend

# Cài đặt các phụ thuộc
flutter pub get

# Chạy trình tạo mã (Freezed, json_serializable, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Chạy trên Chrome (web)
flutter run -d chrome

# Chạy trên thiết bị đã kết nối
flutter run

# Chạy với chế độ theo dõi hot reload
flutter run -d chrome --hot
```

---

## 6. Cấu trúc dự án

```
smart-brain-vn/
├── backend/                        # Máy chủ Rust API
│   ├── src/
│   │   ├── main.rs                # Điểm vào (Entry point), khởi tạo server
│   │   ├── state.rs               # AppState (dependency injection)
│   │   ├── config/                # Cấu hình môi trường
│   │   ├── auth/                  # JWT, băm mật khẩu, extractors
│   │   ├── handlers/             # Các trình xử lý HTTP route (lớp mỏng)
│   │   ├── services/             # Logic nghiệp vụ
│   │   ├── repository/           # Truy cập cơ sở dữ liệu (sqlx queries)
│   │   ├── models/               # Các mô hình domain
│   │   ├── dto/                  # Các DTO yêu cầu/phản hồi
│   │   ├── error.rs              # Enum ApiError
│   │   ├── middleware/           # Giới hạn tốc độ (Rate limiting)
│   │   └── ws/                   # Trình xử lý WebSocket
│   ├── migrations/               # SQL migrations (sqlx)
│   ├── Cargo.toml                # Các phụ thuộc Rust
│   └── Dockerfile                # Build production 4 giai đoạn
├── frontend/                      # Ứng dụng Flutter
│   ├── lib/
│   │   ├── main.dart             # Điểm vào
│   │   ├── app.dart              # Widget gốc SmartMathApp
│   │   ├── core/                 # Hạ tầng dùng chung
│   │   │   ├── constants/        # API endpoints, cấu hình
│   │   │   ├── network/          # Dio client, interceptors
│   │   │   ├── router/           # Cấu hình GoRouter
│   │   │   ├── storage/          # Lưu trữ cục bộ Hive
│   │   │   ├── theme/            # Material 3 theme
│   │   │   └── error/            # Xử lý lỗi toàn cục
│   │   ├── features/             # Các mô-đun tính năng (tổng cộng 12)
│   │   │   ├── auth/
│   │   │   ├── home/
│   │   │   ├── practice/
│   │   │   ├── progress/
│   │   │   ├── competition/
│   │   │   ├── leaderboard/
│   │   │   ├── achievements/
│   │   │   ├── gamification/
│   │   │   ├── learning_tips/
│   │   │   ├── parent/
│   │   │   ├── exercises/
│   │   │   └── settings/
│   │   └── shared/               # Các widget dùng chung
│   ├── test/                     # Kiểm thử Widget & unit (207+)
│   ├── pubspec.yaml              # Các phụ thuộc Flutter
│   ├── Dockerfile                # Build web 2 giai đoạn
│   └── nginx.conf                # Điều hướng SPA + API proxy
├── docs/                          # Tài liệu
│   ├── architecture.vi.md        # Kiến trúc hệ thống
│   ├── api.vi.md                 # Tài liệu API
│   ├── database.vi.md            # Sơ đồ cơ sở dữ liệu
│   ├── development.vi.md         # Tệp này
│   └── deployment.vi.md          # Triển khai production
├── .github/workflows/            # Luồng CI/CD
│   ├── rust.yml                  # CI cho Backend
│   └── flutter.yml               # CI cho Frontend
├── docker-compose.yml            # Điều phối toàn bộ hệ thống
├── .env.example                  # Mẫu tệp môi trường
└── README.md                     # Tổng quan dự án
```

---

## 7. Quy ước lập trình

### 7.1 Backend (Rust)

#### Phong cách (Style)

- **Trình định dạng (Formatter)**: `cargo fmt` (rustfmt) — được thực thi trong CI
- **Trình kiểm tra (Linter)**: `cargo clippy` với `-D warnings` — chính sách không có cảnh báo
- **Phiên bản (Edition)**: Rust 2021

#### Quy tắc kiến trúc

| Lớp | Vai trò | Có thể gọi |
|---|---|---|
| **Handlers** | Phân tích HTTP, xác thực đầu vào, trả về phản hồi | Services |
| **Services** | Logic nghiệp vụ, điều phối | Repositories, các Service khác |
| **Repositories** | Chỉ truy vấn cơ sở dữ liệu | Không gì cả (lớp lá) |

- Handlers phải mỏng — không chứa logic nghiệp vụ
- Services sở hữu tất cả các quy tắc nghiệp vụ
- Repositories sử dụng `sqlx::query!` / `sqlx::query_as!` để kiểm tra SQL tại thời điểm biên dịch
- Tất cả các hàm không đồng bộ sử dụng `async fn`, không bao giờ chặn runtime

#### Quy ước đặt tên

| Mục | Quy ước | Ví dụ |
|---|---|---|
| Files | `snake_case` | `user_repository.rs` |
| Structs | `PascalCase` | `CreateUserRequest` |
| Functions | `snake_case` | `get_user_by_id` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_RETRY_COUNT` |
| Type aliases | `PascalCase` | `type DbPool = PgPool` |

#### Xử lý lỗi

- Sử dụng enum `ApiError` cho tất cả các lỗi của handler
- Không bao giờ sử dụng `.unwrap()` trong mã production (chỉ dùng trong test)
- Sử dụng toán tử `?` để lan truyền lỗi
- Ánh xạ các lỗi bên ngoài thành các biến thể của `ApiError`

```rust
// Tốt
let user = repo.find_by_id(id).await.map_err(|_| ApiError::NotFound("User not found"))?;

// Xấu
let user = repo.find_by_id(id).await.unwrap();
```

### 7.2 Frontend (Flutter/Dart)

#### Phong cách (Style)

- **Trình định dạng (Formatter)**: `dart format` — được thực thi trong CI
- **Trình kiểm tra (Linter)**: `flutter analyze` — không lỗi, không cảnh báo
- **Phân tích (Analysis)**: Tùy chỉnh `analysis_options.yaml` với các quy tắc nghiêm ngặt

#### Quy tắc kiến trúc (Kiến trúc sạch - Clean Architecture)

```
Presentation → Domain → Data
(Widgets)    (Models) (Repos)
```

- **Presentation**: Pages, Widgets, StateNotifiers (Riverpod)
- **Domain**: Các mô hình Freezed, giao diện repository (các lớp trừu tượng)
- **Data**: Triển khai repository, nguồn dữ liệu, các lệnh gọi API

#### Cấu trúc mô-đun tính năng

Mỗi tính năng tuân theo đúng mẫu này:

```
features/{name}/
├── data/
│   ├── datasources/
│   │   └── {name}_remote_data_source.dart
│   └── repositories/
│       └── {name}_repository_impl.dart
├── domain/
│   ├── models/
│   │   └── {name}_model.dart          # @freezed
│   └── repositories/
│       └── {name}_repository.dart     # abstract class
├── presentation/
│   ├── notifiers/
│   │   └── {name}_notifier.dart       # StateNotifier<AsyncValue<T>>
│   ├── pages/
│   │   └── {name}_page.dart
│   └── widgets/
│       └── {name}_widget.dart
└── providers.dart                      # Các provider Riverpod
```

#### Quy ước đặt tên

| Mục | Quy ước | Ví dụ |
|---|---|---|
| Files | `snake_case` | `practice_notifier.dart` |
| Classes | `PascalCase` | `PracticeNotifier` |
| Variables | `camelCase` | `currentStreak` |
| Constants | `camelCase` | `defaultTimeout` |
| Providers | `camelCase + Provider` | `practiceNotifierProvider` |
| Routes | `kebab-case` | `/learning-tips` |

#### Quản lý trạng thái (State Management)

- Sử dụng `Riverpod` duy nhất — không dùng `setState`, không `BLoC`, không `Provider`
- Tất cả các trạng thái không đồng bộ sử dụng `AsyncValue<T>` (loading/error/data)
- StateNotifiers quản lý trạng thái tính năng
- Các Provider được giới hạn trong phạm vi tính năng (định nghĩa trong `providers.dart`)

---

## 8. Chiến lược nhánh (Branch Strategy)

### Mô hình nhánh

```
main (sẵn sàng cho production)
  └── product (nhánh tích hợp)
       ├── feature/practice-screen
       ├── feature/leaderboard-api
       ├── fix/auth-token-refresh
       └── chore/update-dependencies
```

### Đặt tên nhánh

| Tiền tố | Mục đích | Ví dụ |
|---|---|---|
| `feature/` | Tính năng mới | `feature/competition-screen` |
| `fix/` | Sửa lỗi | `fix/jwt-expiry-handling` |
| `chore/` | Bảo trì, phụ thuộc, CI | `chore/update-flutter-sdk` |
| `refactor/` | Tái cấu trúc mã | `refactor/auth-service` |
| `docs/` | Chỉ tài liệu | `docs/api-reference` |
| `test/` | Thêm kiểm thử | `test/practice-integration` |

### Luồng công việc

```bash
# 1. Tạo nhánh tính năng từ product
git checkout product
git pull origin product
git checkout -b feature/my-feature

# 2. Thực hiện thay đổi, commit thường xuyên
git add .
git commit -m "feat: add practice timer component"

# 3. Push và tạo PR
git push -u origin feature/my-feature
gh pr create --base product --title "feat: add practice timer"

# 4. Sau khi PR được chấp thuận, merge vào product
# 5. Product → main được thực hiện thông qua quy trình phát hành (release)
```

### Định dạng thông điệp Commit

Tuân theo [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]
[optional footer]
```

| Loại | Mô tả |
|---|---|
| `feat` | Tính năng mới |
| `fix` | Sửa lỗi |
| `refactor` | Tái cấu trúc mã (không thay đổi hành vi) |
| `test` | Thêm hoặc sửa kiểm thử |
| `docs` | Thay đổi tài liệu |
| `chore` | Build, CI, cập nhật phụ thuộc |
| `style` | Định dạng (không thay đổi mã) |
| `perf` | Cải thiện hiệu suất |

**Ví dụ:**
```
feat(practice): add combo multiplier animation
fix(auth): handle expired refresh token gracefully
refactor(backend): extract XP calculation to service
test(progress): add chart widget tests
docs: update API endpoint documentation
chore: bump Flutter SDK to 3.29.3
```

---

## 9. Luồng công việc phát triển (Development Workflow)

### Luồng công việc hàng ngày

```bash
# 1. Lấy các thay đổi mới nhất
git checkout product && git pull

# 2. Khởi động các dịch vụ
docker compose up -d

# 3. Làm việc trên nhánh của bạn
git checkout feature/my-feature

# 4. Thay đổi Backend → tự động tải lại
cd backend && cargo watch -x run

# 5. Thay đổi Frontend → hot reload
cd frontend && flutter run -d chrome

# 6. Chạy kiểm thử trước khi commit
cd backend && cargo test
cd frontend && flutter test

# 7. Commit và push
git add . && git commit -m "feat: ..."
git push
```

### Danh sách kiểm tra khi Review mã

- [ ] Tất cả kiểm thử đều vượt qua (`cargo test`, `flutter test`)
- [ ] Không có cảnh báo lint (`cargo clippy`, `flutter analyze`)
- [ ] Mã đã được định dạng (`cargo fmt --check`, `dart format --set-exit-if-changed .`)
- [ ] Các tính năng mới có kiểm thử
- [ ] Các thay đổi API được lập tài liệu
- [ ] Không có `.unwrap()` trong mã production
- [ ] Không có các tương đương của `as any` / `@ts-ignore`
- [ ] Xử lý lỗi tuân theo mẫu `ApiError`

---

## 10. Kiểm thử (Testing)

### Kiểm thử Backend

```bash
cd backend

# Chạy tất cả kiểm thử
cargo test

# Chạy mô-đun kiểm thử cụ thể
cargo test test_auth

# Chạy với đầu ra (output)
cargo test -- --nocapture

# Chạy với backtrace
RUST_BACKTRACE=1 cargo test
```

**Yêu cầu kiểm thử:**
- Kiểm thử đơn vị (Unit tests) cho các service và tiện ích
- Kiểm thử tích hợp (Integration tests) yêu cầu PostgreSQL và DragonflyDB (sử dụng các dịch vụ Docker)
- CI tự động chạy các kiểm thử với các dịch vụ container

### Kiểm thử Frontend

```bash
cd frontend

# Chạy tất cả kiểm thử (207+ bài kiểm thử)
flutter test

# Chạy tệp kiểm thử cụ thể
flutter test test/features/practice/presentation/widgets/practice_timer_test.dart

# Chạy với độ bao phủ (coverage)
flutter test --coverage

# Tạo báo cáo độ bao phủ HTML
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Các mẫu kiểm thử:**
- Kiểm thử Widget cho tất cả các thành phần UI
- Kiểm thử đơn vị cho các notifier và repository
- Giả lập (Mock) các phụ thuộc bằng `Mockito` / giả lập thủ công
- Sử dụng `ProviderScope.overrides` để kiểm thử Riverpod

---

## 11. Các tác vụ thường gặp

### Thêm một Endpoint API mới

1. Định nghĩa các cấu trúc request/response trong `backend/src/dto/` hoặc `backend/src/models/`
2. Viết hàm trình xử lý trong `backend/src/handlers/`
3. Thêm route trong `backend/src/handlers/mod.rs`
4. Thêm logic service trong `backend/src/services/` (nếu cần)
5. Thêm truy vấn repository trong `backend/src/repository/` (nếu cần)
6. Viết kiểm thử
7. Cập nhật tài liệu API

### Thêm một mô-đun tính năng mới (Frontend)

```bash
cd frontend/lib/features

# Tạo cấu trúc tính năng
mkdir -p my_feature/{data/{datasources,repositories},domain/{models,repositories},presentation/{notifiers,pages,widgets}}
touch my_feature/providers.dart
```

1. Định nghĩa các mô hình Freezed trong `domain/models/`
2. Định nghĩa giao diện repository trong `domain/repositories/`
3. Triển khai nguồn dữ liệu trong `data/datasources/`
4. Triển khai repository trong `data/repositories/`
5. Tạo StateNotifier trong `presentation/notifiers/`
6. Xây dựng widget trang trong `presentation/pages/`
7. Đăng ký route trong `core/router/app_router.dart`
8. Thêm tên route trong `core/router/route_names.dart`
9. Chạy trình tạo mã: `dart run build_runner build --delete-conflicting-outputs`
10. Viết các bài kiểm thử widget

### Thêm một Database Migration

```bash
cd backend

# Tạo tệp migration mới
sqlx migrate add create_new_table

# Chỉnh sửa tệp đã tạo
vim migrations/YYYYMMDDHHMMSS_create_new_table.sql

# Chạy migration
sqlx migrate run

# Xác minh
sqlx migrate info
```

### Cập nhật các phụ thuộc (Dependencies)

```bash
# Backend
cd backend
cargo update

# Frontend
cd frontend
flutter pub upgrade
dart run build_runner build --delete-conflicting-outputs
```

---

## 12. Xử lý sự cố (Troubleshooting)

### Cổng đã được sử dụng (Port Already in Use)

```bash
# Tìm tiến trình sử dụng cổng
lsof -i :3000  # backend
lsof -i :5432  # postgres
lsof -i :6379  # dragonfly

# Đóng nó
kill -9 <PID>

# Hoặc thay đổi cổng trong .env
BACKEND_PORT=3001
POSTGRES_PORT=5433
```

### Build Docker thất bại

```bash
# Làm sạch cache Docker
docker compose down -v
docker system prune -f
docker compose build --no-cache
docker compose up -d
```

### Database Migration thất bại

```bash
# Kiểm tra trạng thái migration
cd backend && sqlx migrate info

# Hoàn tác migration cuối cùng
sqlx migrate revert

# Đặt lại cơ sở dữ liệu (sẽ xóa dữ liệu!)
docker compose down -v
docker compose up -d postgres
sqlx migrate run
```

### Các vấn đề về trình tạo mã Flutter

```bash
cd frontend

# Làm sạch và tạo lại
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs

# Nếu vẫn thất bại, hãy xóa các tệp đã tạo
find . -name "*.g.dart" -delete
find . -name "*.freezed.dart" -delete
dart run build_runner build --delete-conflicting-outputs
```

### Lỗi biên dịch Cargo sau khi Pull

```bash
cd backend

# Làm sạch các thành phần build
cargo clean
cargo build

# Nếu gặp vấn đề với sqlx offline mode
cargo sqlx prepare
```

### Kết nối DragonflyDB bị từ chối

```bash
# Kiểm tra xem có đang chạy không
docker compose ps dragonfly

# Kiểm tra kết nối
redis-cli -a smartmath_redis_dev ping
# Kết quả mong đợi: PONG

# Nếu không chạy
docker compose up -d dragonfly
```

---

*Cập nhật lần cuối: Tháng 3 năm 2026*
