#!/usr/bin/env bash

# # # # # # # # # # # # # # # # # # # # # # # #
#       SPT - Server pre-launch script        #
#                v2025.11-4                   #
# # # # # # # # # # # # # # # # # # # # # # # #

# Uncomment line below if you installed ASP.NET in your home directory
# export DOTNET_ROOT=$HOME/.dotnet

# Auto-detect DOTNET_ROOT from a system `dotnet` if not already set.
# This helps on NixOS (and similar) when the user installed dotnet-aspnetcore_9
# (providing `dotnet` in PATH) but did not (or could not) set the session variable.
# The packaged `spt-server` from the flake bakes the value in instead.
if [[ -z "${DOTNET_ROOT:-}" ]] && command -v dotnet &>/dev/null; then
    # Derive from the runtime list (works on NixOS even if DOTNET_ROOT is not in the
    # environment; the `dotnet` binary knows where its 9.0 AspNet bits live).
    # Example line: Microsoft.AspNetCore.App 9.0.16 [/nix/store/.../share/dotnet/shared/...]
    extracted=$(dotnet --list-runtimes 2>/dev/null | awk '
        /AspNet.*9\.0/ {
            if (match($0, /\[(.+)\]/, a)) {
                p = a[1]
                sub(/\/shared\/.*/,"",p)
                print p
                exit
            }
        }' || true)
    if [[ -n "$extracted" && -d "$extracted" ]]; then
        export DOTNET_ROOT="$extracted"
    fi
fi

ROOT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )"
TERMINALS=( "alacritty" "ghostty" "foot" "terminator" "ptyxis" "cosmic-terminal"
            "kgx" "konsole" "gnome-terminal" "xfce4-terminal" "kitty" "xterm" )

err() {
    local msg="${1}"  status=${2:-1}
    if [[ $status != 0 ]]; then
        echo "ERROR: $msg (Exit code: $status)"
        exit $status
    fi
}

# NOTE: `aspnetcore-runtime` on the host system is not available from a sandboxed environment.
# Theirfore we use `flatpak-spawn --host` to launch the server on the host system.
# This might not work with some Wayland desktop portals e.g. `cinnamon/xapp`
m_run() {
    if [[ -z "${FLATPAK_SANDBOX_DIR}" ]]; then "$@"
    else flatpak-spawn --host "$@" || err "Command \"flatpak-spawn --host $@\" failed"; fi
}

if [[ -n $( m_run pidof "SPT.Server.Linux" ) ]]; then
    err "Another instance of the server is already running"
fi

for term in "${TERMINALS[@]}"; do
    if ! m_run command -v "$term" &>/dev/null; then continue; fi
    cd "${ROOT_PATH}/SPT" || continue
    # Try launching; if this terminal fails (e.g. xterm can't open a display),
    # try the next one in the list instead of aborting immediately.
    if m_run "$term" -e "./SPT.Server.Linux"; then
        exit 0
    else
        continue
    fi
done

# Fallback for environments where no graphical terminal from the list could
# be successfully used (e.g. nix run with its restricted PATH, SSH, headless,
# or when the only "terminal" found was xterm without a working display).
# This makes `nix run ...#spt-additions -- run server` (and similar) work
# by attaching directly, matching the behavior of the dedicated `spt-server`
# package.
echo "No supported terminal emulator could be used to open a new window."
echo "Falling back to running the server directly in the current terminal..."
cd "${ROOT_PATH}/SPT" || exit 1
exec ./SPT.Server.Linux "$@"
