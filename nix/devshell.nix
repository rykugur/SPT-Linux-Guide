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
      winetricks
      cabextract
    ]);

  env = {
    DOTNET_ROOT = "${pkgs.dotnet-aspnetcore_9}/share/dotnet";
  };

  shellHook = ''
    echo "SPT Linux Guide dev shell"
    echo ""
    echo "Script dependencies in PATH:"
    echo "  umu-run:   $(command -v umu-run || echo 'MISSING')"
    echo "  7zzs:      $(command -v 7zzs || echo 'MISSING')"
    echo "  steam-run: $(command -v steam-run || echo 'MISSING')"
    echo "  jq / xxd:  $(command -v jq || echo 'MISSING') / $(command -v xxd || echo 'MISSING')"
    echo ""
    echo "Runnables: nix run .#spt-additions | .#spt-server | .#spt-launcher"
  '';
}
