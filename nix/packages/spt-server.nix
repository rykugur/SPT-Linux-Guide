# The spt-server launcher package.
# Provides a hermetic DOTNET_ROOT and a nice Ctrl+C handler.
{ pkgs, lib, media ? ../media }:

let
  serverScript = pkgs.writeShellScriptBin "spt-server" ''
    set -euo pipefail

    export DOTNET_ROOT="${pkgs.dotnet-aspnetcore_9}/share/dotnet"

    CONFIG_FILE="''${XDG_CONFIG_HOME:-$HOME/.config}/spt-additions/app.conf"
    SPT_DIR=""

    if [ -f "$CONFIG_FILE" ]; then
      SPT_DIR=$(grep '^spt-path=' "$CONFIG_FILE" | tail -1 | cut -d= -f2- | tr -d '"' || true)
    fi

    if [ -z "$SPT_DIR" ] || [ ! -d "$SPT_DIR" ]; then
      SPT_DIR="''${SPTARKOV_PATH:-$HOME/Games/SPTarkov}"
    fi

    SERVER_DIR="$SPT_DIR/SPT"
    SERVER_BIN="$SERVER_DIR/SPT.Server.Linux"

    if [ ! -f "$SERVER_BIN" ]; then
      echo "ERROR: SPT Server binary not found at: $SERVER_BIN" >&2
      echo "  - Install SPT using the guide (spt-additions or Lutris additions)" >&2
      echo "  - Or set the env var: SPTARKOV_PATH=/path/to/SPTarkov" >&2
      echo "  - Or add 'spt-path=\"/path/to/SPTarkov\"' to $CONFIG_FILE" >&2
      exit 1
    fi

    if pidof "SPT.Server.Linux" >/dev/null 2>&1; then
      echo "ERROR: Another instance of the server is already running" >&2
      exit 1
    fi

    cd "$SERVER_DIR"

    # Run the server in the background under our control so we can
    # handle Ctrl+C (SIGINT) and other signals cleanly. This gives
    # a much nicer shutdown experience than a raw exec, especially
    # when launched via `nix run`.
    "$SERVER_BIN" "$@" &
    SERVER_PID=$!

    echo "SPT Server is running (PID $SERVER_PID)."
    echo "Press Ctrl+C to stop it (the launcher will forward the signal)."

    cleanup() {
        echo ""
        echo "Shutting down SPT server..."
        if kill -TERM "$SERVER_PID" 2>/dev/null; then
            wait "$SERVER_PID" 2>/dev/null || true
        fi
        echo "Server stopped."
    }

    trap cleanup INT TERM

    # Wait for the server process to exit (on its own or after our signal).
    wait "$SERVER_PID"
    EXIT_CODE=$?

    # Avoid running cleanup again on normal exit
    trap - EXIT

    exit $EXIT_CODE
  '';
in
pkgs.symlinkJoin {
  name = "spt-server";
  paths = [ serverScript ];
  postBuild = ''
    mkdir -p $out/share/applications
    cat > $out/share/applications/spt-server.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Type=Application
Name=SPT Server
Comment=SPTarkov (Single Player Tarkov) Server
Exec=spt-server
Icon=spt_server
Terminal=true
Categories=Game;ActionGame;Simulation;
StartupNotify=false
DESKTOP_EOF

    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp ${media}/coverart/apps/lutris_sptarkov-server.png \
       $out/share/icons/hicolor/256x256/apps/spt_server.png
  '';
  meta = {
    description = "Command and desktop launcher for the SPTarkov Linux server (SPT.Server.Linux). Bakes in the correct ASP.NET runtime.";
    longDescription = ''
      After installing SPT via the SPT-Linux-Guide, add this package (or run it directly).
      It discovers your install (via the guide's config or SPTARKOV_PATH), ensures
      DOTNET_ROOT, and launches the native server.

      Ships a .desktop so "SPT Server" appears in application menus/launchers.
    '';
    homepage = "https://github.com/MadByteDE/SPT-Linux-Guide";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "spt-server";
  };
}
