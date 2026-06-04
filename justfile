# SPT Linux Guide development tasks
# Run with: just <task>

# Show this list
default:
    @just --list

# Check bash syntax of the installer script
check:
    bash -n scripts/spt-additions
    echo "Syntax OK"

# Run shellcheck (if available)
lint:
    shellcheck scripts/spt-additions || echo "shellcheck not installed or script has issues"

# Quick smoke test of the script (no side effects)
version:
    ./scripts/spt-additions --no-ansi --no-prompt version

# Show what the script thinks the native deps situation is (will trigger NixOS notes on NixOS)
deps:
    ./scripts/spt-additions --no-ansi --no-prompt 2>&1 | cat || true

# Run the script with steam-run explicitly (useful for testing the FHS path on NixOS)
run-steam *args:
    steam-run ./scripts/spt-additions --no-ansi {{args}}

# Clean common cache dirs used by the script (careful!)
clean-cache:
    rm -rf ~/.cache/spt-additions
    echo "Cleared ~/.cache/spt-additions (re-run script to repopulate)"

# Enter the dev shell explicitly (if not using direnv)
shell:
    nix develop

# Run the SPT server directly in the current terminal (best for seeing errors on NixOS)
# It tries to find the install path from the script's config file first.
server:
    #!/usr/bin/env bash
    set -euo pipefail
    CONFIG_FILE="$HOME/.config/spt-additions/app.conf"
    SPT_DIR=""
    if [ -f "$CONFIG_FILE" ]; then
        SPT_DIR=$(grep '^spt-path=' "$CONFIG_FILE" | head -1 | cut -d= -f2- | tr -d '"')
    fi
    if [ -z "$SPT_DIR" ] || [ ! -d "$SPT_DIR" ]; then
        SPT_DIR="$HOME/Games/SPTarkov"
    fi
    if [ ! -d "$SPT_DIR" ]; then
        echo "SPTarkov directory not found."
        echo "Check your config: $CONFIG_FILE (look for spt-path=...)"
        echo "Or search for the binary: find ~ -name 'SPT.Server.Linux' 2>/dev/null"
        echo "Then cd to the directory containing 'launch-server.sh' and run: ./SPT/SPT.Server.Linux"
        exit 1
    fi
    echo "Running server from $SPT_DIR ..."
    cd "$SPT_DIR/SPT"
    ./SPT.Server.Linux

# Run the SPT launcher (via the script, which applies NixOS wrappers if needed)
launcher:
    ./scripts/spt-additions run launcher

# Format the justfile itself (requires just)
fmt:
    just --fmt --unstable
