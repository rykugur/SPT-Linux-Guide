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
# Assumes default install path; adjust if you chose a different one during install.
server:
    cd ~/Games/SPTarkov || cd "$HOME/Games/SPTarkov" || { echo "SPT dir not found at ~/Games/SPTarkov"; exit 1; }
    echo "Running server from $(pwd) ..."
    ./SPT/SPT.Server.Linux

# Run the SPT launcher (via the script, which applies NixOS wrappers if needed)
launcher:
    ./scripts/spt-additions run launcher

# Format the justfile itself (requires just)
fmt:
    just --fmt --unstable
