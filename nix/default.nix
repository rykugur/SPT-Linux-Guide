# nix/default.nix
#
# Single import point for everything under nix/.
# Re-exports the mod support (pure) and provides small helpers so that flake.nix
# (and advanced consumers) can stay tiny.
#
# Usage (inside this repo or as a flake input's ./nix):
#   let spt = import ./nix { inherit lib; };
#   ...
#   coreDeps = spt.mkCoreScriptDeps pkgs;
#   server = import spt.packageDefs."spt-server" { inherit pkgs; lib = pkgs.lib; };
#   packages = spt.mkSptPackages pkgs lib;
#
# The mod bits (supportedSptVersion, mkSptMod, mkSptMods, sptModVersions) are
# re-exported at the top level for convenience:
#   spt.supportedSptVersion
#   mods = spt.mkSptMods pkgs spt.supportedSptVersion;
#
# See README.md in this directory for more (bumping versions, adding mods,
# dependency handling, etc.).

{ lib }:

let
  # Pure mod data + builders (version map, mkSptMod, mkSptMods, resolve, etc.).
  modSupport = import ./spt-mods.nix { inherit lib; };

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
  mkSptPackages = pkgs: _lib:  # second arg ignored (callers sometimes pass lib for symmetry); kept so existing call sites with 2 args continue to work
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

  modules = {
    homeManager = ./modules/home-manager/spt.nix;
  };
in

modSupport // {
  inherit
    mkCoreScriptDeps
    packageDefs
    mkSptPackages
    devshell
    modules
    ;
}
