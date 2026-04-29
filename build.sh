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

echo "Building with agents: ${AGENTS:-none (default Codex only)}"

# Default to pushing if --push flag is provided
PUSH_FLAG=""
if [ "$1" = "--push" ]; then
    PUSH_FLAG="--push"
fi

# Build with Docker BuildKit
DOCKER_BUILDKIT=1 docker build \
    --build-arg "CODING_AGENTS=$AGENTS" \
    -t ghcr.io/rorar/vibe-kanban-docker:latest \
    -t ghcr.io/rorar/vibe-kanban-docker:local \
    $PUSH_FLAG \
    .

echo "Build complete!"
