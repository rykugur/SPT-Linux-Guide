# nix/default.nix
#
# Helpers for the runnable artifacts exposed by this flake:
#   spt-additions, spt-server, spt-launcher (plus dev shell).
#
# This repository's flake now concerns itself *only* with these runnable tools.
# The declarative mod system (spt-mods.nix + builders) and the Home Manager
# module have been removed from the flake's public outputs (lib, homeModules,
# overlay sptMods, etc.).
#
# Those pieces remain in the repo under nix/ as reference / starting points if
# you want to maintain your own mod map, mkSptMod, and HM module in a personal
# configuration flake (importing this repo only for the launchers/tools).
#
# Usage (for advanced consumers or inside this repo):
#   let spt = import ./nix { inherit lib; };
#   coreDeps = spt.mkCoreScriptDeps pkgs;
#   pkgs = spt.mkSptPackages pkgs lib;  # { spt-additions, spt-server, ... }

{ lib }:

rec {
  # The list of packages that the spt-additions script, spt-server, spt-launcher,
  # and the dev shell all need at runtime. Single source of truth.
  # Callers must use a pkgs set that has `config.allowUnfree = true`.
  mkCoreScriptDeps = pkgs: with pkgs; [
    umu-launcher
    steam-run
    jq
    unixtools.xxd
    python3
    curl
    p7zip
    # Provide 7zzs exactly as the spt-additions script expects it.
    (runCommand "7zzs" { } ''
      mkdir -p $out/bin
      ln -s ${lib.getExe p7zip} $out/bin/7zzs
    '')
    # ASP.NET Core for SPT.Server.Linux (native) + any version checks the script does.
    dotnet-aspnetcore_9
  ];

  # File paths to the individual package builders.
  # Import them yourself with the right arguments when you want full control.
  packageDefs = {
    spt-server = ./packages/spt-server.nix;
    spt-additions = ./packages/spt-additions.nix;
    spt-launcher = ./packages/spt-launcher.nix;
  };

  # Build the three public packages (plus `default`) for the given pkgs.
  # The pkgs must allow unfree (for steam-run etc.).
  # This centralizes the import boilerplate (media path for the icon is handled by the default
  # inside packages/spt-server.nix so it always resolves correctly from the file's location).
  mkSptPackages = pkgs: _lib:  # second arg ignored for call-site compatibility
    let
      coreScriptDeps = mkCoreScriptDeps pkgs;
      sptServer = import packageDefs.spt-server {
        inherit pkgs;
        lib = pkgs.lib;
        # media omitted: spt-server.nix has a correct default (../../media relative to *its* location)
      };
      sptAdditions = import packageDefs.spt-additions {
        inherit pkgs coreScriptDeps;
      };
      sptLauncher = import packageDefs.spt-launcher {
        inherit pkgs sptAdditions;
      };
    in {
      spt-additions = sptAdditions;
      spt-server    = sptServer;
      spt-launcher  = sptLauncher;
      default       = sptServer;
    };

  # Path to the devshell expression (imported by flake with minimal args).
  devshell = ./devshell.nix;

  # NOTE: There is no longer a `modules` or modSupport re-export.
  # See nix/spt-mods.nix and nix/modules/home-manager/spt.nix in the source
  # tree if you want to vendor/adapt that logic into your own flake.
}
