#!/bin/bash
# Runtime installation script for optional tools
# Installs coding agents, testing tools, and Playwright browsers at container startup
# Supports both space-separated and comma-separated values
# Includes version checking to only update when newer versions available

set -e

# Configure npm cache location (use /home/node for non-root compatibility)
npm config set cache /home/node/.npm --location=global
npm config set prefix /usr/local --location=global

# Configure pipx for non-root compatibility
export PIPX_HOME=/home/node/.local/share/pipx
export PIPX_BIN_DIR=/home/node/.local/bin
export PATH="$PIPX_BIN_DIR:$PATH"

# Link node_modules from persistent mount if exists (for cached installations)
if [ -d "/home/node/npm-modules" ] && [ ! -L "/usr/local/lib/node_modules" ]; then
    ln -sf /home/node/npm-modules /usr/local/lib/node_modules 2>/dev/null || true
fi

# ============================================================================
# Version Checking Functions
# ============================================================================

# Check if network is available
check_network() {
    curl -s --max-time 5 https://registry.npmjs.org > /dev/null 2>&1
}

# Get installed npm package version
get_installed_npm_version() {
    local package="$1"
    npm list -g "$package" --depth=0 --json 2>/dev/null | \
        grep -oP '"version":\s*"\K[^"]+' | head -1
}

# Get latest npm package version from registry
get_latest_npm_version() {
    local package="$1"
    npm view "$package" version 2>/dev/null
}

# Compare two version strings (semver)
# Returns: newer, older, same
version_compare() {
    local v1="$1" v2="$2"
    
    # Handle empty versions
    [ -z "$v1" ] && [ -z "$v2" ] && echo "same" && return
    [ -z "$v1" ] && echo "older" && return
    [ -z "$v2" ] && echo "newer" && return
    
    # Same version
    [ "$v1" = "$v2" ] && echo "same" && return
    
    # Use sort -V for semver comparison
    local sorted=$(echo -e "$v1\n$v2" | sort -V | tail -1)
    
    if [ "$sorted" = "$v1" ]; then
        echo "older"
    else
        echo "newer"
    fi
}

# Check and install npm package with version comparison
# Usage: check_and_install_npm <package> <name>
check_and_install_npm() {
    local package="$1"
    local name="${2:-$package}"
    
    local installed=$(get_installed_npm_version "$package")
    local latest=$(get_latest_npm_version "$package")
    
    if [ -z "$installed" ]; then
        echo "[startup] Installing $name (not found)..."
        npm install -g "$package"
        return
    fi
    
    if [ -z "$latest" ]; then
        echo "[startup] WARN: Cannot check latest version for $name, using installed: $installed"
        return
    fi
    
    local comparison=$(version_compare "$installed" "$latest")
    
    case "$comparison" in
        newer)
            echo "[startup] $name: installed=$installed (newer than latest=$latest), keeping..."
            ;;
        same)
            echo "[startup] $name: already latest ($installed)"
            ;;
        older)
            echo "[startup] Upgrading $name: $installed → $latest"
            npm install -g "$package"
            ;;
    esac
}

# Check and install Playwright browser
# Usage: check_and_install_playwright_browser <browser>
check_and_install_playwright_browser() {
    local browser="$1"
    local cache_path="/home/node/.cache/ms-playwright"
    
    # Check if browser is already installed (folder exists)
    if [ -d "$cache_path" ]; then
        # List installed browsers
        local installed=$(ls -d "$cache_path"/*-"$browser"-* 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "")
        
        if [ -n "$installed" ]; then
            echo "[startup] $browser: already cached ($installed)"
            return
        fi
    fi
    
    echo "[startup] Installing Playwright browser: $browser"
    export PLAYWRIGHT_BROWSERS_PATH="$cache_path"
    npx playwright install "$browser"
}

# Check and install Python tool via pipx
# Usage: check_and_install_python <tool>
check_and_install_python() {
    local tool="$1"
    
    # Check if already installed
    if command -v "$tool" &> /dev/null; then
        echo "[startup] Python tool $tool: already installed"
        # Upgrade if newer version available
        if pipx upgrade "$tool" 2>/dev/null; then
            echo "[startup] Python tool $tool: upgraded"
        fi
        return
    fi
    
    echo "[startup] Installing Python tool: $tool"
    pipx install "$tool"
}

# Check and install Cursor CLI
# Usage: check_and_install_cursor
check_and_install_cursor() {
    # Cursor doesn't expose version API, so check if binary exists
    if command -v cursor &> /dev/null; then
        echo "[startup] Cursor: already installed"
        return
    fi
    
    echo "[startup] Installing Cursor CLI..."
    HOME=/home/node \
    PATH=/home/node/.local/bin:$PATH \
    curl -fsSL https://cursor.com/install | bash
}

# ============================================================================
# Main Installation Logic
# ============================================================================

echo "[startup] Checking for optional tools to install..."

# Agent name to npm package mapping
declare -A AGENT_MAP=(
    ["claude"]="@anthropic-ai/claude-code"
    ["gemini"]="@google/gemini-cli"
    ["copilot"]="@github/copilot"
    ["amp"]="@sourcegraph/amp"
    ["opencode"]="opencode-ai"
    ["droid"]="@factory/cli"
    ["clauderouter"]="@musistudio/claude-code-router"
    ["qwen"]="@qwen-code/qwen-code"
)

# Agents installed via curl (not npm)
declare -a AGENTS_CURL=("cursor")

# Function to normalize list: replace commas with spaces, collapse multiple spaces, trim
normalize_list() {
    local input="$1"
    # Replace commas with spaces, collapse multiple spaces to one, trim leading/trailing
    echo "$input" | sed 's/,/ /g' | tr -s ' ' | sed 's/^ //;s/ $//'
}

# Install coding agents from RUNTIME_AGENTS env var (space or comma-separated)
if [ -n "$RUNTIME_AGENTS" ]; then
    AGENTS=$(normalize_list "$RUNTIME_AGENTS")
    echo "[startup] Checking coding agents: $AGENTS"
    for agent in $AGENTS; do
        # Skip empty items
        [ -z "$agent" ] && continue
        
        # Install via curl (not npm)
        if [[ " ${AGENTS_CURL[@]} " =~ " ${agent} " ]]; then
            check_and_install_cursor
            continue
        fi
        
        if [ -n "${AGENT_MAP[$agent]}" ]; then
            check_and_install_npm "${AGENT_MAP[$agent]}" "$agent"
        else
            # Try as-is if not in map (for custom packages)
            check_and_install_npm "$agent" "$agent"
        fi
    done
fi

# Install Playwright and browsers from RUNTIME_PLAYWRIGHT_BROWSERS env var
if [ -n "$RUNTIME_PLAYWRIGHT_BROWSERS" ]; then
    BROWSERS=$(normalize_list "$RUNTIME_PLAYWRIGHT_BROWSERS")
    echo "[startup] Checking Playwright browsers: $BROWSERS"
    # Install Playwright core if not present
    if ! npm list -g @playwright/test &> /dev/null; then
        npm install -g @playwright/test playwright
    fi
    # Check and install each browser
    for browser in $BROWSERS; do
        [ -z "$browser" ] && continue
        check_and_install_playwright_browser "$browser"
    done
fi

# Install testing tools from RUNTIME_TESTING_TOOLS env var
if [ -n "$RUNTIME_TESTING_TOOLS" ]; then
    TOOLS=$(normalize_list "$RUNTIME_TESTING_TOOLS")
    echo "[startup] Checking testing tools: $TOOLS"
    for tool in $TOOLS; do
        [ -z "$tool" ] && continue
        check_and_install_npm "$tool" "testing:$tool"
    done
fi

# Install SVG tools from RUNTIME_SVG_TOOLS env var
if [ -n "$RUNTIME_SVG_TOOLS" ]; then
    TOOLS=$(normalize_list "$RUNTIME_SVG_TOOLS")
    echo "[startup] Checking SVG tools: $TOOLS"
    for tool in $TOOLS; do
        [ -z "$tool" ] && continue
        check_and_install_npm "$tool" "svg:$tool"
    done
fi

# Install additional Python tools from RUNTIME_PYTHON_TOOLS env var
if [ -n "$RUNTIME_PYTHON_TOOLS" ]; then
    TOOLS=$(normalize_list "$RUNTIME_PYTHON_TOOLS")
    echo "[startup] Checking Python tools: $TOOLS"
    for tool in $TOOLS; do
        [ -z "$tool" ] && continue
        check_and_install_python "$tool"
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
