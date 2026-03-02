# ==============================================
# SmartMath Kids - Rust Backend Dockerfile
# Multi-stage build with cargo-chef for dependency caching
# ==============================================

# Stage 1: Chef - Install cargo-chef
FROM rust:1.88-bookworm AS chef
RUN cargo install cargo-chef
WORKDIR /app

# Stage 2: Planner - Prepare dependency recipe
FROM chef AS planner
COPY Cargo.toml Cargo.lock* ./
COPY src ./src
RUN cargo chef prepare --recipe-path recipe.json

# Stage 3: Builder - Build dependencies then application
FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies (cached unless Cargo.toml/lock change)
RUN cargo chef cook --release --recipe-path recipe.json
# Build application
COPY Cargo.toml Cargo.lock* ./
COPY src ./src
COPY migrations ./migrations
RUN cargo build --release

# Stage 4: Runtime - Minimal production image
FROM debian:bookworm-slim AS runtime
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --shell /bin/false --create-home appuser

WORKDIR /app

COPY --from=builder /app/target/release/smartmath-backend ./
COPY --from=builder /app/migrations ./migrations

# Set ownership and switch to non-root user
RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 3000

ENV RUST_LOG=info

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:3000/api/v1/health || exit 1

CMD ["./smartmath-backend"]
