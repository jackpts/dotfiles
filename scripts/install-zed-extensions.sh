#!/usr/bin/env bash
# Install Zed extensions and MCP servers from dotfiles
# Usage: ./install-zed-extensions.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
EXTENSIONS_FILE="$DOTFILES_DIR/.config/zed/extensions.json"
SERVERS_FILE="$DOTFILES_DIR/.config/zed/servers.json"

echo "=== Zed Setup ==="

# Install extensions
if [[ -f "$EXTENSIONS_FILE" ]]; then
    echo ""
    echo "Installing Zed extensions..."
    extensions=$(jq -r '.extensions[]' "$EXTENSIONS_FILE")

    for ext in $extensions; do
        echo "  → Installing: $ext"
        zed --install-extension "$ext" 2>/dev/null || echo "    (may already be installed)"
    done
    echo "✓ Extensions installed"
else
    echo "⚠ extensions.json not found, skipping extensions"
fi

# Install MCP servers
if [[ -f "$SERVERS_FILE" ]]; then
    echo ""
    echo "Checking MCP servers..."

    # Check for context7
    if jq -e '.context_servers[] | select(.name == "mcp-server-context7")' "$SERVERS_FILE" > /dev/null 2>&1; then
        if ! command -v mcp-server-context7 &> /dev/null; then
            echo "  → Installing mcp-server-context7..."
            npm install -g @context7/mcp-server
        else
            echo "  ✓ mcp-server-context7 already installed"
        fi
    fi

    # Check for custom agent servers
    echo ""
    echo "Checking custom agent servers..."

    if ! command -v qwen &> /dev/null; then
        echo "  → qwen CLI not found. Install with: npm install -g @anthropic/qwen-code"
    else
        echo "  ✓ qwen CLI installed"
    fi

    if ! command -v gemini &> /dev/null; then
        echo "  → gemini CLI not found. Install with: npm install -g @google/gemini-cli"
    else
        echo "  ✓ gemini CLI installed"
    fi

    if ! command -v kimi &> /dev/null; then
        echo "  → kimi CLI not found. Install from: https://github.com/MoonshotAI/Kimi"
    else
        echo "  ✓ kimi CLI installed"
    fi
else
    echo "⚠ servers.json not found, skipping MCP servers"
fi

echo ""
echo "✓ Done! Restart Zed to apply extensions and servers."
