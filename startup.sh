#!/bin/bash
# Runtime installation script for optional tools
# Installs coding agents, testing tools, and Playwright browsers at container startup
# Supports both space-separated and comma-separated values

set -e

echo "[startup] Checking for optional tools to install..."

# Agent name to npm package mapping
declare -A AGENT_MAP=(
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

# Function to normalize list (replace commas with spaces)
normalize_list() {
    echo "$1" | tr ',' ' '
}

# Install coding agents from RUNTIME_AGENTS env var (space or comma-separated)
if [ -n "$RUNTIME_AGENTS" ]; then
    AGENTS=$(normalize_list "$RUNTIME_AGENTS")
    echo "[startup] Installing coding agents: $AGENTS"
    for agent in $AGENTS; do
        # Trim whitespace
        agent=$(echo "$agent" | xargs)
        if [ -n "$agent" ]; then
            if [ -n "${AGENT_MAP[$agent]}" ]; then
                echo "[startup] Installing ${AGENT_MAP[$agent]}..."
                npm install -g "${AGENT_MAP[$agent]}"
            else
                # Try as-is if not in map (for custom packages)
                echo "[startup] Installing $agent..."
                npm install -g "$agent"
            fi
        fi
    done
fi

# Install Playwright and browsers from RUNTIME_PLAYWRIGHT_BROWSERS env var
if [ -n "$RUNTIME_PLAYWRIGHT_BROWSERS" ]; then
    BROWSERS=$(normalize_list "$RUNTIME_PLAYWRIGHT_BROWSERS")
    echo "[startup] Installing Playwright with browsers: $BROWSERS"
    npm install -g @playwright/test playwright
    npx playwright install $BROWSERS
fi

# Install testing tools from RUNTIME_TESTING_TOOLS env var
if [ -n "$RUNTIME_TESTING_TOOLS" ]; then
    TOOLS=$(normalize_list "$RUNTIME_TESTING_TOOLS")
    echo "[startup] Installing testing tools: $TOOLS"
    npm install -g $TOOLS
fi

echo "[startup] Tool installation complete."

# Execute the original command
exec "$@"
