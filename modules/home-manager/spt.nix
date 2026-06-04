{ config, lib, pkgs, ... }:

let
  cfg = config.programs.spt;
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
        List of individual SPT mod packages (see flake.lib.mkSptMod).

        Each package should unpack to a directory tree with BepInEx/ and/or
        SPT/ subdirectories. These will be merged into your SPTarkov install
        directory via home-manager activation (non-destructive by default:
        uses --ignore-existing).

        Example:
          mods = [
            (inputs.spt-linux-guide.lib.mkSptMod {
              pkgs = pkgs;
              pname = "uifixes";
              version = "5.3.9";
              url = "https://github.com/tyfon7/UIFixes/releases/download/v5.3.9/Tyfon-UIFixes-5.3.9.zip";
              hash = "sha256-...";
            })
          ];
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

    # Merge declared mods into the mutable SPT install dir on activation.
    # This mirrors the archive extraction used by spt-additions (BepInEx/ + SPT/ merge).
    # Uses rsync --ignore-existing to avoid clobbering manual/user files.
    home.activation.applySptMods = lib.hm.dag.entryAfter ["writeBoundary"] ''
      SPT_DIR="$HOME/Games/SPTarkov"
      if [ -d "$SPT_DIR" ] && [ ${toString (builtins.length cfg.mods)} -gt 0 ]; then
        echo "Applying ${toString (builtins.length cfg.mods)} nix-managed SPT mod(s)..."
        ${lib.concatMapStringsSep "\n" (mod: ''
          if [ -d "${mod}/BepInEx" ]; then
            ${pkgs.rsync}/bin/rsync -a --ignore-existing "${mod}/BepInEx/" "$SPT_DIR/BepInEx/"
          fi
          if [ -d "${mod}/SPT" ]; then
            ${pkgs.rsync}/bin/rsync -a --ignore-existing "${mod}/SPT/" "$SPT_DIR/SPT/"
          fi
        '') cfg.mods}
        echo "Mod merge complete. Restart client/server if running."
      fi
    '';
  };
}
