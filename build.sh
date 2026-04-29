#!/bin/bash
# Build script with simplified agent naming
# Usage: ./build.sh [--push]

set -e

# Agent name to npm package mapping (case-insensitive)
declare -A AGENT_MAP=(
    ["codex"]="@openai/codex"
    ["claude"]="@anthropic-ai/claude-code"
    ["gemini"]="@google/gemini-cli"
    ["copilot"]="@githubnext/copilot-cli"
    ["amp"]="amp-code"
    ["cursor"]="@cursor/cli"
    ["opencode"]="@opencode-ai/cli"
    ["droid"]="droid-cli"
    ["clauderouter"]="claude-code-router"
    ["qwen"]="qwen-code"
)

# Load .env file if exists
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

# Build AGENTS string from .env variables
AGENTS=""
for key in "${!AGENT_MAP[@]}"; do
    env_var="AGENT_${key^^}=true"
    # Check if the variable is set to true/1
    if [ "${!env_var}" = "true" ] || [ "${!env_var}" = "1" ]; then
        if [ -n "$AGENTS" ]; then
            AGENTS="$AGENTS ${AGENT_MAP[$key]}"
        else
            AGENTS="${AGENT_MAP[$key]}"
        fi
    fi
done

# Build Playwright browsers string from .env variable (for runtime installation)
RUNTIME_PLAYWRIGHT_BROWSERS="${RUNTIME_PLAYWRIGHT_BROWSERS:-}"

# Build testing tools string from .env variable (for runtime installation)
RUNTIME_TESTING_TOOLS="${RUNTIME_TESTING_TOOLS:-}"

echo "Building image (tools installed at runtime via environment variables)"
echo "Available runtime agents: claude, gemini, copilot, amp, cursor, opencode, droid, clauderouter, qwen"
echo "Available runtime browsers: chromium, firefox, webkit"
echo "Available runtime tools: vitest, jest, msw"

# Default to pushing if --push flag is provided
PUSH_FLAG=""
if [ "$1" = "--push" ]; then
    PUSH_FLAG="--push"
fi

# Build with Docker BuildKit
# Note: Tools are now installed at runtime via environment variables
DOCKER_BUILDKIT=1 docker build \
    -t ghcr.io/rorar/vibe-kanban-docker:latest \
    -t ghcr.io/rorar/vibe-kanban-docker:local \
    $PUSH_FLAG \
    .

echo "Build complete!"
