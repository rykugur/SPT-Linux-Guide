# The development shell for the guide.
# Provides tools for the spt-additions script and related tooling.
{ pkgs, lib, ... }:

let
  # Pull the (now single-source) core runtime deps via the nix/ entry point.
  spt = import ./default.nix { inherit lib; };
  coreScriptDeps = spt.mkCoreScriptDeps pkgs;
in

pkgs.mkShell {
  packages =
    coreScriptDeps
    ++ (with pkgs; [
      # Dev-only helpers (not needed by the packaged scripts).
      shellcheck
      shfmt
      git
      just
      file
      which
      tree
      winetricks
      cabextract
    ]);

  env = {
    DOTNET_ROOT = "${pkgs.dotnet-aspnetcore_9}/share/dotnet";
  };

  shellHook = ''
    echo "SPT Linux Guide dev shell (flake-parts)"
    echo "=========================================="
    echo ""
    echo "Script dependencies:"
    echo "  umu-run:   $(command -v umu-run || echo 'MISSING')"
    echo "  7zzs:      $(command -v 7zzs || echo 'MISSING')"
    echo "  steam-run: $(command -v steam-run || echo 'MISSING')"
    echo "  jq / xxd : $(command -v jq || echo 'MISSING') / $(command -v xxd || echo 'MISSING')"
    echo ""
    echo "NixOS note: The script auto-detects /etc/NIXOS + steam-run and wraps umu-run for FHS."
    echo "            You can also run the installer directly with the wrapped package:"
    echo "            nix run .#spt-additions   (or from a flake input)"
    echo ""
    echo "Try: just --list"
    echo "     just server      (direct, inside this shell)"
    echo "     just spt-server  (via the packaged launcher)"
    echo ""
    echo "DOTNET_ROOT for server: $DOTNET_ROOT"
    echo ""
    echo "Useful runnable packages from this flake (or as an input):"
    echo "  nix run .#spt-additions   # the installer"
    echo "  nix run .#spt-server      # the dedicated server"
    echo "  nix run .#spt-launcher    # the SPT client/launcher GUI"
  '';
}
