# ==============================================
# SmartMath Kids - Flutter Web Dockerfile
# Multi-stage build: Flutter build → nginx serving
# ==============================================

# Stage 1: Build Flutter web
FROM ghcr.io/cirruslabs/flutter:3.29.3 AS builder
WORKDIR /app

# Copy dependency files first for layer caching
COPY pubspec.yaml pubspec.lock* ./

# Install dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Run code generation (freezed, json_serializable, riverpod_generator)
RUN dart run build_runner build --delete-conflicting-outputs

# Build Flutter web with CanvasKit renderer
RUN flutter build web --release --web-renderer canvaskit

# Stage 2: Serve with nginx
FROM nginx:1.27-alpine AS runtime

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy Flutter web build output
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
