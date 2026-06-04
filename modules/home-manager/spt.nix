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
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [ cfg.package ]
      ++ lib.optional cfg.server.enable cfg.server.package
      ++ lib.optional cfg.launcher.enable cfg.launcher.package;

    home.sessionVariables = lib.mkIf cfg.dotnetRoot.enable {
      DOTNET_ROOT = "${cfg.dotnetRoot.package}/share/dotnet";
    };
  };
}
