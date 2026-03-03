# SmartMath Kids — Developer Onboarding Guide

Welcome to the SmartMath Kids project! This guide will get you from zero to productive in under 30 minutes.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Repository Setup](#2-repository-setup)
3. [Environment Configuration](#3-environment-configuration)
4. [Running with Docker (Recommended)](#4-running-with-docker-recommended)
5. [Running Locally (Without Docker)](#5-running-locally-without-docker)
6. [Project Structure](#6-project-structure)
7. [Coding Conventions](#7-coding-conventions)
8. [Branch Strategy](#8-branch-strategy)
9. [Development Workflow](#9-development-workflow)
10. [Testing](#10-testing)
11. [Common Tasks](#11-common-tasks)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Prerequisites

### Required

| Tool | Version | Check | Install |
|---|---|---|---|
| **Git** | 2.x+ | `git --version` | [git-scm.com](https://git-scm.com/) |
| **Docker** | 24+ | `docker --version` | [docker.com](https://docs.docker.com/get-docker/) |
| **Docker Compose** | v2+ | `docker compose version` | Included with Docker Desktop |

### For Local Development (Optional)

| Tool | Version | Check | Install |
|---|---|---|---|
| **Rust** | 1.88+ | `rustc --version` | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| **Flutter** | 3.29.3 | `flutter --version` | [flutter.dev](https://docs.flutter.dev/get-started/install) |
| **PostgreSQL** | 16 | `psql --version` | [postgresql.org](https://www.postgresql.org/download/) |
| **sqlx-cli** | 0.8 | `sqlx --version` | `cargo install sqlx-cli --no-default-features --features rustls,postgres` |

---

## 2. Repository Setup

```bash
# Clone the repository
git clone https://github.com/your-org/smart-brain-vn.git
cd smart-brain-vn

# Verify project structure
ls -la
# Expected: backend/  frontend/  docker-compose.yml  .env.example  docs/
```

---

## 3. Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Review and customize (defaults work for development)
cat .env
```

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `POSTGRES_USER` | `smartmath` | PostgreSQL username |
| `POSTGRES_PASSWORD` | `smartmath_dev_pass` | PostgreSQL password |
| `POSTGRES_DB` | `smartmath` | Database name |
| `POSTGRES_PORT` | `5432` | PostgreSQL port |
| `REDIS_PASSWORD` | `smartmath_redis_dev` | DragonflyDB password |
| `REDIS_PORT` | `6379` | DragonflyDB port |
| `BACKEND_PORT` | `3000` | Backend API port |
| `JWT_SECRET` | (dev secret) | JWT signing key (**change in production**) |
| `JWT_ACCESS_TOKEN_EXPIRES_IN` | `15m` | Access token TTL |
| `JWT_REFRESH_TOKEN_EXPIRES_IN` | `7d` | Refresh token TTL |
| `RUST_LOG` | `info,smartmath_backend=debug` | Log level filter |
| `APP_ENV` | `development` | Application environment |
| `FRONTEND_PORT` | `8080` | Frontend web port |
| `API_BASE_URL` | `http://localhost:3000/api/v1` | API base URL for frontend |
| `WS_URL` | `ws://localhost:3000/ws` | WebSocket URL for frontend |

> **Security**: Never commit `.env` files. The `.env.example` contains safe defaults only.

---

## 4. Running with Docker (Recommended)

The fastest way to get the full stack running.

### Start Everything

```bash
# Build and start all services
docker compose up --build -d

# Watch the logs
docker compose logs -f
```

### Verify Services

```bash
# Check all containers are running
docker compose ps

# Expected output:
# NAME                  STATUS        PORTS
# smartmath-postgres    Up (healthy)  0.0.0.0:5432->5432/tcp
# smartmath-dragonfly   Up (healthy)  0.0.0.0:6379->6379/tcp
# smartmath-backend     Up (healthy)  0.0.0.0:3000->3000/tcp
# smartmath-frontend    Up            0.0.0.0:8080->80/tcp

# Test backend health
curl http://localhost:3000/api/v1/health
# Expected: {"status":"healthy","db_connected":true,"redis_connected":true,...}

# Open frontend
open http://localhost:8080
```

### Service URLs

| Service | URL | Purpose |
|---|---|---|
| **Frontend** | http://localhost:8080 | Flutter web app |
| **Backend API** | http://localhost:3000/api/v1 | REST API |
| **WebSocket** | ws://localhost:3000/ws | Real-time events |
| **Swagger Docs** | http://localhost:3000/docs/backend-apis | API documentation |
| **PostgreSQL** | localhost:5432 | Database (connect with `psql`) |
| **DragonflyDB** | localhost:6379 | Cache (connect with `redis-cli`) |

### Common Docker Commands

```bash
# Stop all services
docker compose down

# Stop and remove volumes (fresh start)
docker compose down -v

# Rebuild a specific service
docker compose build backend
docker compose up -d backend

# View logs for specific service
docker compose logs -f backend

# Execute command inside container
docker compose exec backend sh
docker compose exec postgres psql -U smartmath -d smartmath
```

---

## 5. Running Locally (Without Docker)

### 5.1 Start Infrastructure (Hybrid Mode)

Use the dedicated infrastructure compose file to start only the required services (PostgreSQL & DragonflyDB). This ensures you have the necessary environment without running the application containers.

```bash
# Start infrastructure services
docker compose -f docker-compose.infra.yml up -d
```

### 5.2 Backend

```bash
cd backend

# Copy env (if not already done at root)
export DATABASE_URL="postgres://smartmath:smartmath_dev_pass@localhost:5432/smartmath"
export REDIS_URL="redis://default:smartmath_redis_dev@localhost:6379"
export JWT_SECRET="dev_jwt_secret_change_in_production_minimum_32_chars"
export RUST_LOG="info,smartmath_backend=debug"

# Run database migrations
cargo install sqlx-cli --no-default-features --features rustls,postgres
sqlx migrate run

# Start backend in development mode
cargo run

# Or with auto-reload (install cargo-watch first)
cargo install cargo-watch
cargo watch -x run
```

### 5.3 Frontend

```bash
cd frontend

# Install dependencies
flutter pub get

# Run code generation (Freezed, json_serializable, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Run on Chrome (web)
flutter run -d chrome

# Run on connected device
flutter run

# Run with hot reload watching
flutter run -d chrome --hot
```

---

## 6. Project Structure

```
smart-brain-vn/
├── backend/                        # Rust API server
│   ├── src/
│   │   ├── main.rs                # Entry point, server bootstrap
│   │   ├── state.rs               # AppState (dependency injection)
│   │   ├── config/                # Environment configuration
│   │   ├── auth/                  # JWT, password hashing, extractors
│   │   ├── handlers/             # HTTP route handlers (thin layer)
│   │   ├── services/             # Business logic
│   │   ├── repository/           # Database access (sqlx queries)
│   │   ├── models/               # Domain models
│   │   ├── dto/                  # Request/Response DTOs
│   │   ├── error.rs              # ApiError enum
│   │   ├── middleware/           # Rate limiting
│   │   └── ws/                   # WebSocket handler
│   ├── migrations/               # SQL migrations (sqlx)
│   ├── Cargo.toml                # Rust dependencies
│   └── Dockerfile                # 4-stage production build
├── frontend/                      # Flutter app
│   ├── lib/
│   │   ├── main.dart             # Entry point
│   │   ├── app.dart              # SmartMathApp root widget
│   │   ├── core/                 # Shared infrastructure
│   │   │   ├── constants/        # API endpoints, config
│   │   │   ├── network/          # Dio client, interceptors
│   │   │   ├── router/           # GoRouter configuration
│   │   │   ├── storage/          # Hive local storage
│   │   │   ├── theme/            # Material 3 theme
│   │   │   └── error/            # Global error handling
│   │   ├── features/             # Feature modules (12 total)
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
│   │   └── shared/               # Shared widgets
│   ├── test/                     # Widget & unit tests (207+)
│   ├── pubspec.yaml              # Flutter dependencies
│   ├── Dockerfile                # 2-stage web build
│   └── nginx.conf                # SPA routing + API proxy
├── docs/                          # Documentation
│   ├── architecture.md           # System architecture
│   ├── api.md                    # API reference
│   ├── database.md               # Database schema
│   ├── development.md            # This file
│   └── deployment.md             # Production deployment
├── .github/workflows/            # CI/CD pipelines
│   ├── rust.yml                  # Backend CI
│   └── flutter.yml               # Frontend CI
├── docker-compose.yml            # Full stack orchestration
├── .env.example                  # Environment template
└── README.md                     # Project overview
```

---

## 7. Coding Conventions

### 7.1 Backend (Rust)

#### Style

- **Formatter**: `cargo fmt` (rustfmt) — enforced in CI
- **Linter**: `cargo clippy` with `-D warnings` — zero warnings policy
- **Edition**: Rust 2021

#### Architecture Rules

| Layer | Role | Can Call |
|---|---|---|
| **Handlers** | Parse HTTP, validate input, return response | Services |
| **Services** | Business logic, orchestration | Repositories, other Services |
| **Repositories** | Database queries only | Nothing (leaf layer) |

- Handlers must be thin — no business logic
- Services own all business rules
- Repositories use `sqlx::query!` / `sqlx::query_as!` for compile-time checked SQL
- All async functions use `async fn`, never block the runtime

#### Naming Conventions

| Item | Convention | Example |
|---|---|---|
| Files | `snake_case` | `user_repository.rs` |
| Structs | `PascalCase` | `CreateUserRequest` |
| Functions | `snake_case` | `get_user_by_id` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_RETRY_COUNT` |
| Type aliases | `PascalCase` | `type DbPool = PgPool` |

#### Error Handling

- Use `ApiError` enum for all handler errors
- Never use `.unwrap()` in production code (only tests)
- Use `?` operator for error propagation
- Map external errors to `ApiError` variants

```rust
// Good
let user = repo.find_by_id(id).await.map_err(|_| ApiError::NotFound("User not found"))?;

// Bad
let user = repo.find_by_id(id).await.unwrap();
```

### 7.2 Frontend (Flutter/Dart)

#### Style

- **Formatter**: `dart format` — enforced in CI
- **Linter**: `flutter analyze` — zero errors, zero warnings
- **Analysis**: Custom `analysis_options.yaml` with strict rules

#### Architecture Rules (Clean Architecture)

```
Presentation → Domain → Data
(Widgets)    (Models) (Repos)
```

- **Presentation**: Pages, Widgets, StateNotifiers (Riverpod)
- **Domain**: Freezed models, repository interfaces (abstract classes)
- **Data**: Repository implementations, data sources, API calls

#### Feature Module Structure

Every feature follows this exact pattern:

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
└── providers.dart                      # Riverpod providers
```

#### Naming Conventions

| Item | Convention | Example |
|---|---|---|
| Files | `snake_case` | `practice_notifier.dart` |
| Classes | `PascalCase` | `PracticeNotifier` |
| Variables | `camelCase` | `currentStreak` |
| Constants | `camelCase` | `defaultTimeout` |
| Providers | `camelCase + Provider` | `practiceNotifierProvider` |
| Routes | `kebab-case` | `/learning-tips` |

#### State Management

- Use `Riverpod` exclusively — no `setState`, no `BLoC`, no `Provider`
- All async state uses `AsyncValue<T>` (loading/error/data)
- StateNotifiers manage feature state
- Providers are feature-scoped (defined in `providers.dart`)

---

## 8. Branch Strategy

### Branch Model

```
main (production-ready)
  └── product (integration branch)
       ├── feature/practice-screen
       ├── feature/leaderboard-api
       ├── fix/auth-token-refresh
       └── chore/update-dependencies
```

### Branch Naming

| Prefix | Purpose | Example |
|---|---|---|
| `feature/` | New feature | `feature/competition-screen` |
| `fix/` | Bug fix | `fix/jwt-expiry-handling` |
| `chore/` | Maintenance, deps, CI | `chore/update-flutter-sdk` |
| `refactor/` | Code refactoring | `refactor/auth-service` |
| `docs/` | Documentation only | `docs/api-reference` |
| `test/` | Test additions | `test/practice-integration` |

### Workflow

```bash
# 1. Create feature branch from product
git checkout product
git pull origin product
git checkout -b feature/my-feature

# 2. Make changes, commit frequently
git add .
git commit -m "feat: add practice timer component"

# 3. Push and create PR
git push -u origin feature/my-feature
gh pr create --base product --title "feat: add practice timer"

# 4. After PR approval, merge to product
# 5. Product → main is done via release process
```

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]
[optional footer]
```

| Type | Description |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring (no behavior change) |
| `test` | Adding or fixing tests |
| `docs` | Documentation changes |
| `chore` | Build, CI, dependency updates |
| `style` | Formatting (no code change) |
| `perf` | Performance improvement |

**Examples:**
```
feat(practice): add combo multiplier animation
fix(auth): handle expired refresh token gracefully
refactor(backend): extract XP calculation to service
test(progress): add chart widget tests
docs: update API endpoint documentation
chore: bump Flutter SDK to 3.29.3
```

---

## 9. Development Workflow

### Daily Workflow

```bash
# 1. Pull latest changes
git checkout product && git pull

# 2. Start services
docker compose up -d

# 3. Work on your branch
git checkout feature/my-feature

# 4. Backend changes → auto-reload
cd backend && cargo watch -x run

# 5. Frontend changes → hot reload
cd frontend && flutter run -d chrome

# 6. Run tests before committing
cd backend && cargo test
cd frontend && flutter test

# 7. Commit and push
git add . && git commit -m "feat: ..."
git push
```

### Code Review Checklist

- [ ] All tests pass (`cargo test`, `flutter test`)
- [ ] No lint warnings (`cargo clippy`, `flutter analyze`)
- [ ] Code is formatted (`cargo fmt --check`, `dart format --set-exit-if-changed .`)
- [ ] New features have tests
- [ ] API changes are documented
- [ ] No `.unwrap()` in production code
- [ ] No `as any` / `@ts-ignore` equivalents
- [ ] Error handling follows `ApiError` pattern

---

## 10. Testing

### Backend Tests

```bash
cd backend

# Run all tests
cargo test

# Run specific test module
cargo test test_auth

# Run with output
cargo test -- --nocapture

# Run with backtrace
RUST_BACKTRACE=1 cargo test
```

**Test requirements:**
- Unit tests for services and utilities
- Integration tests require PostgreSQL and DragonflyDB (use Docker services)
- CI runs tests with service containers automatically

### Frontend Tests

```bash
cd frontend

# Run all tests (207+ tests)
flutter test

# Run specific test file
flutter test test/features/practice/presentation/widgets/practice_timer_test.dart

# Run with coverage
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Test patterns:**
- Widget tests for all UI components
- Unit tests for notifiers and repositories
- Mock dependencies with `Mockito` / manual mocks
- Use `ProviderScope.overrides` for Riverpod testing

---

## 11. Common Tasks

### Add a New API Endpoint

1. Define request/response structs in `backend/src/dto/` or `backend/src/models/`
2. Write handler function in `backend/src/handlers/`
3. Add route in `backend/src/handlers/mod.rs`
4. Add service logic in `backend/src/services/` (if needed)
5. Add repository query in `backend/src/repository/` (if needed)
6. Write tests
7. Update API documentation

### Add a New Feature Module (Frontend)

```bash
cd frontend/lib/features

# Create feature structure
mkdir -p my_feature/{data/{datasources,repositories},domain/{models,repositories},presentation/{notifiers,pages,widgets}}
touch my_feature/providers.dart
```

1. Define Freezed models in `domain/models/`
2. Define repository interface in `domain/repositories/`
3. Implement data source in `data/datasources/`
4. Implement repository in `data/repositories/`
5. Create StateNotifier in `presentation/notifiers/`
6. Build page widget in `presentation/pages/`
7. Register route in `core/router/app_router.dart`
8. Add route name in `core/router/route_names.dart`
9. Run code generation: `dart run build_runner build --delete-conflicting-outputs`
10. Write widget tests

### Add a Database Migration

```bash
cd backend

# Create new migration file
sqlx migrate add create_new_table

# Edit the generated file
vim migrations/YYYYMMDDHHMMSS_create_new_table.sql

# Run migration
sqlx migrate run

# Verify
sqlx migrate info
```

### Update Dependencies

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

## 12. Troubleshooting

### Port Already in Use

```bash
# Find process using port
lsof -i :3000  # backend
lsof -i :5432  # postgres
lsof -i :6379  # dragonfly

# Kill it
kill -9 <PID>

# Or change ports in .env
BACKEND_PORT=3001
POSTGRES_PORT=5433
```

### Docker Build Fails

```bash
# Clean Docker cache
docker compose down -v
docker system prune -f
docker compose build --no-cache
docker compose up -d
```

### Database Migration Fails

```bash
# Check migration status
cd backend && sqlx migrate info

# Revert last migration
sqlx migrate revert

# Reset database (destructive!)
docker compose down -v
docker compose up -d postgres
sqlx migrate run
```

### Flutter Code Generation Issues

```bash
cd frontend

# Clean and regenerate
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs

# If still failing, delete generated files
find . -name "*.g.dart" -delete
find . -name "*.freezed.dart" -delete
dart run build_runner build --delete-conflicting-outputs
```

### Cargo Compile Errors After Pull

```bash
cd backend

# Clean build artifacts
cargo clean
cargo build

# If sqlx offline mode issues
cargo sqlx prepare
```

### DragonflyDB Connection Refused

```bash
# Check if running
docker compose ps dragonfly

# Test connection
redis-cli -a smartmath_redis_dev ping
# Expected: PONG

# If not running
docker compose up -d dragonfly
```

---

*Last updated: March 2026*
