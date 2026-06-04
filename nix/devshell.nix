# The development shell for the guide.
# Provides tools for the spt-additions script and the mod system.
{ pkgs, lib, coreScriptDeps, dotnet-aspnetcore_9, ... }:

pkgs.mkShell {
  packages = with pkgs; [
    # Core script runtime (duplicated from coreScriptDeps for the shell experience)
    umu-launcher
    steam-run
    jq
    unixtools.xxd
    python3
    curl
    p7zip
    (pkgs.runCommand "7zzs" { } ''
      mkdir -p $out/bin
      ln -s ${lib.getExe p7zip} $out/bin/7zzs
    '')
    dotnet-aspnetcore_9

    # Dev helpers
    shellcheck
    shfmt
    git
    just
    file
    which
    tree
    winetricks
    cabextract
  ];

  env = {
    DOTNET_ROOT = "${dotnet-aspnetcore_9}/share/dotnet";
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
    echo "  Use lib.mkSptMods for versioned mods (e.g. (lib.mkSptMods pkgs).sain )"
  '';
}
