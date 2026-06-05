# Home Manager module for SPT tools + declarative mods (reference).
#
# NOTE: This module is no longer exported by the SPT-Linux-Guide flake
# (homeModules.spt etc. have been removed). The flake now only concerns
# itself with the runnable artifacts.
#
# This file is kept as a reference / template. You are expected to maintain
# an equivalent (or improved) module in your personal flake, importing the
# tool packages from the SPT-Linux-Guide input as needed.
#
# It previously provided:
#   programs.spt.enable / .server.enable / .launcher.enable
#   programs.spt.mods (list of mkSptMod packages, auto-merged via rsync)
#   DOTNET_ROOT handling

{ config, lib, pkgs, ... }:

let
  cfg = config.programs.spt;

  # Resolve the full transitive closure of mods (including dependencies declared
  # via passthru.dependencies in mkSptMod). Dependencies are listed first so
  # that base frameworks are applied before the mods that depend on them.
  resolveModClosure = mods:
    let
      go = m: [ m ] ++ lib.concatMap go (m.passthru.dependencies or [ ]);
    in
      lib.unique (lib.flatten (map go mods));

  allMods = resolveModClosure cfg.mods;

  # A single store path containing the union of all mod file trees.
  # symlinkJoin merges the BepInEx/ and SPT/ directories from the closure.
  # If there are file-level collisions, the last one in the list wins.
  modEnv = pkgs.symlinkJoin {
    name = "spt-mods-env";
    paths = allMods;
  };
in
{
  options.programs.spt = {
    enable = lib.mkEnableOption "SPT Linux tools (installer, server launcher, client launcher)";

    package = lib.mkPackageOption pkgs "spt-additions" {
      example = "inputs.spt.packages.\${pkgs.system}.spt-additions (or use the overlay)";
    };

    server = {
      enable = lib.mkEnableOption "SPT server launcher (spt-server)";

      package = lib.mkPackageOption pkgs "spt-server" {
        example = "inputs.spt.packages.\${pkgs.system}.spt-server (or use the overlay)";
      };
    };

    launcher = {
      enable = lib.mkEnableOption "SPT client/launcher (spt-launcher)";

      package = lib.mkPackageOption pkgs "spt-launcher" {
        example = "inputs.spt.packages.\${pkgs.system}.spt-launcher (or use the overlay)";
      };
    };

    dotnetRoot = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to set the DOTNET_ROOT session variable.

          This is required for the native Linux SPT server (SPT.Server.Linux)
          to find the ASP.NET runtime on NixOS.
        '';
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.dotnet-aspnetcore_9;
        description = "The dotnet-aspnetcore package to derive DOTNET_ROOT from.";
      };
    };

    mods = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = ''
        List of "root" SPT mod packages (see flake.lib.mkSptMod).

        Only list the mods you directly want (e.g. SAIN). Their declared
        dependencies (BigBrain, Waypoints, etc.) will be pulled in
        automatically via the package's passthru.dependencies.

        Each package should unpack to a directory tree with BepInEx/ and/or
        SPT/ subdirectories. The full closure will be merged into your
        SPTarkov install directory via home-manager activation
        (non-destructive by default: uses --ignore-existing).

        Example:
          mods = [ sain ];  # where sain = mkSptMod { dependencies = [ bigbrain waypoints ]; ... }
      '';
    };
  };

  config = lib.mkIf (cfg.enable || cfg.mods != []) {
    home.packages =
      lib.optional (cfg.package != null) cfg.package
      ++ lib.optional cfg.server.enable cfg.server.package
      ++ lib.optional cfg.launcher.enable cfg.launcher.package;

    home.sessionVariables = lib.mkIf cfg.dotnetRoot.enable {
      DOTNET_ROOT = "${cfg.dotnetRoot.package}/share/dotnet";
    };

    # Merge the full mod closure (with deps) into the mutable SPT install dir.
    # We build one modEnv in the store and rsync from it. This mirrors the
    # archive extraction used by spt-additions.
    home.activation.applySptMods = lib.hm.dag.entryAfter ["writeBoundary"] ''
      SPT_DIR="$HOME/Games/SPTarkov"
      if [ -d "$SPT_DIR" ] && [ -d "${modEnv}" ]; then
        echo "Applying ${toString (builtins.length allMods)} nix-managed SPT mod(s) (including transitive dependencies)..."
        if [ -d "${modEnv}/BepInEx" ]; then
          ${pkgs.rsync}/bin/rsync -a --ignore-existing "${modEnv}/BepInEx/" "$SPT_DIR/BepInEx/"
        fi
        if [ -d "${modEnv}/SPT" ]; then
          ${pkgs.rsync}/bin/rsync -a --ignore-existing "${modEnv}/SPT/" "$SPT_DIR/SPT/"
        fi
        echo "Mod merge complete. Restart client/server if running."
      fi
    '';
  };
}
