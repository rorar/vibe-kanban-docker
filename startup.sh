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

# Function to normalize list: replace commas with spaces, collapse multiple spaces, trim
normalize_list() {
    local input="$1"
    # Replace commas with spaces, collapse multiple spaces to one, trim leading/trailing
    echo "$input" | sed 's/,/ /g' | tr -s ' ' | sed 's/^ //;s/ $//'
}

# Function to install a list of tools
install_tools() {
    local list="$1"
    local type="$2"
    
    for item in $list; do
        # Skip empty items
        [ -z "$item" ] && continue
        echo "[startup] Installing $type: $item..."
        npm install -g "$item"
    done
}

# Install coding agents from RUNTIME_AGENTS env var (space or comma-separated)
if [ -n "$RUNTIME_AGENTS" ]; then
    AGENTS=$(normalize_list "$RUNTIME_AGENTS")
    echo "[startup] Installing coding agents: $AGENTS"
    for agent in $AGENTS; do
        # Skip empty items
        [ -z "$agent" ] && continue
        
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
    BROWSERS=$(normalize_list "$RUNTIME_PLAYWRIGHT_BROWSERS")
    echo "[startup] Installing Playwright with browsers: $BROWSERS"
    npm install -g @playwright/test playwright
    npx playwright install $BROWSERS
fi

# Install testing tools from RUNTIME_TESTING_TOOLS env var
if [ -n "$RUNTIME_TESTING_TOOLS" ]; then
    TOOLS=$(normalize_list "$RUNTIME_TESTING_TOOLS")
    echo "[startup] Installing testing tools: $TOOLS"
    install_tools "$TOOLS" "testing tool"
fi

# Install SVG tools from RUNTIME_SVG_TOOLS env var
if [ -n "$RUNTIME_SVG_TOOLS" ]; then
    TOOLS=$(normalize_list "$RUNTIME_SVG_TOOLS")
    echo "[startup] Installing SVG tools: $TOOLS"
    install_tools "$TOOLS" "SVG tool"
fi

# Install additional Python tools from RUNTIME_PYTHON_TOOLS env var
if [ -n "$RUNTIME_PYTHON_TOOLS" ]; then
    TOOLS=$(normalize_list "$RUNTIME_PYTHON_TOOLS")
    echo "[startup] Installing Python tools: $TOOLS"
    for tool in $TOOLS; do
        [ -z "$tool" ] && continue
        echo "[startup] Installing Python tool: $tool..."
        pipx install "$tool"
    done
fi

echo "[startup] Tool installation complete."

# Display welcome message with dynamic content based on installed tools
echo ""
echo "========================================"
echo "  Vibe Kanban Docker - Welcome!"
echo "========================================"
echo ""
echo "Installed Tools:"
echo "  - OpenAI Codex (always installed)"
echo "  - SVGO (always installed)"
if [ -n "$RUNTIME_AGENTS" ]; then
    echo "  - Additional agents: $RUNTIME_AGENTS"
fi
if [ -n "$RUNTIME_PLAYWRIGHT_BROWSERS" ]; then
    echo "  - Playwright browsers: $RUNTIME_PLAYWRIGHT_BROWSERS"
fi
if [ -n "$RUNTIME_TESTING_TOOLS" ]; then
    echo "  - Testing tools: $RUNTIME_TESTING_TOOLS"
fi
if [ -n "$RUNTIME_PYTHON_TOOLS" ]; then
    echo "  - Python tools: $RUNTIME_PYTHON_TOOLS"
fi
echo ""
echo "Getting Started:"
echo "  - Access the app at: http://localhost:8085"
echo "  - To start vibe-kanban: bash -lc vibe-kanban"
echo ""
echo "SVG Tools (always available):"
echo "  - librsvg: rsvg-convert -.svg -.png"
echo "  - SVGO: npx svgo -i input.svg -o output.svg"
echo ""
echo "Agent Commands:"
echo "  - Codex: codex"
if [ -n "$RUNTIME_AGENTS" ]; then
    for agent in $(echo "$RUNTIME_AGENTS" | sed 's/,/ /g'); do
        case "$agent" in
            claude)        echo "  - Claude Code: claude" ;;
            gemini)        echo "  - Gemini CLI: gemini" ;;
            copilot)       echo "  - GitHub Copilot: gh copilot" ;;
            amp)           echo "  - Amp: amp" ;;
            cursor)        echo "  - Cursor: cursor" ;;
            opencode)      echo "  - OpenCode: opencode" ;;
            droid)         echo "  - Droid: droid" ;;
            clauderouter)  echo "  - Claude Code Router: ccr" ;;
            qwen)          echo "  - Qwen Code: qwen" ;;
            *)             echo "  - $agent: $agent" ;;
        esac
    done
fi
echo ""
echo "Configuration Locations:"
echo "  - Vibe Kanban: /home/node/.local/share/vibe-kanban"
echo "  - Codex: ~/.codex"
echo "  - GitHub CLI: ~/.config/gh"
if [ -n "$RUNTIME_AGENTS" ]; then
    echo ""
    echo "Agent Configs:"
    for agent in $(echo "$RUNTIME_AGENTS" | sed 's/,/ /g'); do
        case "$agent" in
            claude)        echo "  - Claude Code: ~/.claude" ;;
            gemini)        echo "  - Gemini CLI: ~/.gemini" ;;
            copilot)       echo "  - GitHub Copilot: ~/.copilot" ;;
            amp)           echo "  - Amp: ~/.amp" ;;
            cursor)        echo "  - Cursor: ~/.cursor" ;;
            opencode)      echo "  - OpenCode: ~/.config/opencode" ;;
            droid)         echo "  - Droid: ~/.droid" ;;
            clauderouter)  echo "  - Claude Code Router: ~/.claude-code-router" ;;
            qwen)          echo "  - Qwen Code: ~/.qwen" ;;
            *)             echo "  - $agent: ~/$agent" ;;
        esac
    done
fi
if [ -n "$RUNTIME_PLAYWRIGHT_BROWSERS" ]; then
    echo ""
    echo "Playwright:"
    echo "  - Config: ./playwright.config.ts"
    echo "  - Run tests: npx playwright test"
    echo "  - Single browser: npx playwright test --project=chromium"
    echo "  - View report: npx playwright show-report"
fi
if [ -n "$RUNTIME_TESTING_TOOLS" ]; then
    echo ""
    echo "Testing:"
    if echo "$RUNTIME_TESTING_TOOLS" | grep -q "vitest"; then
        echo "  - Vitest config: ./vitest.config.ts"
        echo "  - Run tests: npx vitest run"
    fi
    if echo "$RUNTIME_TESTING_TOOLS" | grep -q "jest"; then
        echo "  - Jest config: ./jest.config.js"
        echo "  - Run tests: npx jest"
    fi
fi
if [ -n "$RUNTIME_PYTHON_TOOLS" ]; then
    echo ""
    echo "Python Tools:"
    echo "  - Installed: $RUNTIME_PYTHON_TOOLS"
fi
echo ""
echo "Documentation:"
echo "  - Vibe Kanban: https://vibekanban.com/docs"
echo "  - Codex: https://developers.openai.com/codex"
if [ -n "$RUNTIME_AGENTS" ]; then
    for agent in $(echo "$RUNTIME_AGENTS" | sed 's/,/ /g'); do
        case "$agent" in
            claude)        echo "  - Claude Code: https://code.claude.com" ;;
            gemini)        echo "  - Gemini CLI: https://geminicli.com/docs" ;;
            copilot)       echo "  - GitHub Copilot: https://docs.github.com/en/copilot" ;;
            amp)           echo "  - Amp: https://ampcode.com/manual" ;;
            cursor)        echo "  - Cursor: https://cursor.com/docs/cli" ;;
            opencode)      echo "  - OpenCode: https://opencode.ai/docs" ;;
            droid)         echo "  - Droid: https://docs.factory.ai" ;;
            clauderouter)  echo "  - CCR: https://github.com/musistudio/claude-code-router" ;;
            qwen)          echo "  - Qwen Code: https://qwenlm.github.io/qwen-code-docs" ;;
        esac
    done
fi
if [ -n "$RUNTIME_PLAYWRIGHT_BROWSERS" ]; then
    echo "  - Playwright: https://playwright.dev/docs"
fi
if [ -n "$RUNTIME_PYTHON_TOOLS" ]; then
    echo "  - pipx: https://pipx.pypa.io"
fi
echo "  - SVGO: https://github.com/svg/svgo"
if echo "$RUNTIME_TESTING_TOOLS" | grep -q "vitest"; then
    echo "  - Vitest: https://vitest.dev/guide"
fi
echo ""
echo "For more info: https://github.com/rorar/vibe-kanban-docker"
echo "========================================"
echo ""

# Execute the original command
exec "$@"
