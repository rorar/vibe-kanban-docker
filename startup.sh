#!/bin/bash
# Runtime installation script for optional tools
# Installs coding agents, testing tools, and Playwright browsers at container startup

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

# Install coding agents from RUNTIME_AGENTS env var (space-separated)
if [ -n "$RUNTIME_AGENTS" ]; then
    echo "[startup] Installing coding agents: $RUNTIME_AGENTS"
    for agent in $RUNTIME_AGENTS; do
        if [ -n "${AGENT_MAP[$agent]}" ]; then
            echo "[startup] Installing ${AGENT_MAP[$agent]}..."
            npm install -g "${AGENT_MAP[$agent]}"
        else
            # Try as-is if not in map (for custom packages)
            echo "[startup] Installing $agent..."
            npm install -g "$agent"
        fi
    done
fi

# Install Playwright and browsers from RUNTIME_PLAYWRIGHT_BROWSERS env var
if [ -n "$RUNTIME_PLAYWRIGHT_BROWSERS" ]; then
    echo "[startup] Installing Playwright with browsers: $RUNTIME_PLAYWRIGHT_BROWSERS"
    npm install -g @playwright/test playwright
    npx playwright install $RUNTIME_PLAYWRIGHT_BROWSERS
fi

# Install testing tools from RUNTIME_TESTING_TOOLS env var
if [ -n "$RUNTIME_TESTING_TOOLS" ]; then
    echo "[startup] Installing testing tools: $RUNTIME_TESTING_TOOLS"
    npm install -g $RUNTIME_TESTING_TOOLS
fi

echo "[startup] Tool installation complete."

# Execute the original command
exec "$@"
