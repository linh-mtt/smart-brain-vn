#!/bin/bash
# Script to run backend with hot reload enabled using cargo-watch

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if cargo-watch is installed
if ! command_exists cargo-watch; then
  echo "📦 cargo-watch not found. Installing..."
  cargo install cargo-watch
  if [ $? -ne 0 ]; then
    echo "❌ Failed to install cargo-watch. Please install it manually: cargo install cargo-watch"
    exit 1
  fi
  echo "✅ cargo-watch installed successfully."
fi

echo "🚀 Starting Backend with Hot Reload..."
echo "📝 Watching for changes in src/..."

# Run cargo watch
# -x run: Execute 'cargo run' on change
# -w src: Watch 'src' directory
# -c: Clear screen before each run
cargo watch -x run -w src -c
