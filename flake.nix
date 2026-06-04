{
  description = "SPT-Linux-Guide: tools and launchers for running SPTarkov on Linux, with strong NixOS support. Usable as a flake input for dev shells, wrapped scripts, and (future) modules.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, self, ... }:
    let
      spt = import ./nix/spt-mods.nix { lib = inputs.nixpkgs.lib; };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { config, self', inputs', pkgs, system, lib, ... }:
        let
          # We need allowUnfree for steam-run and potentially other gaming-related tools.
          pkgs' = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          # === Common packages used by both the dev shell and the wrapped scripts ===
          coreScriptDeps = with pkgs'; [
            umu-launcher
            steam-run
            jq
            unixtools.xxd
            python3
            curl
            p7zip
            # Provide 7zzs exactly as the spt-additions script expects it
            (pkgs'.runCommand "7zzs" { } ''
              mkdir -p $out/bin
              ln -s ${lib.getExe p7zip} $out/bin/7zzs
            '')
            # ASP.NET for the native Linux server (SPT.Server.Linux) and the script's checks
            dotnet-aspnetcore_9
          ];

          # The three main runnable tools are defined in ./packages/*.nix for cleanliness.
          sptServer = import ./packages/spt-server.nix { pkgs = pkgs'; lib = lib; };
          sptAdditions = import ./packages/spt-additions.nix { pkgs = pkgs'; inherit coreScriptDeps; };
          sptLauncher = import ./packages/spt-launcher.nix { pkgs = pkgs'; sptAdditions = sptAdditions; };

        in
        {
          # Development shell for working on the guide itself (especially the spt-additions script
          # and NixOS-specific paths). Provides every tool the script expects plus dev helpers.
          devShells.default = import ./nix/devshell.nix {
            pkgs = pkgs';
            lib = lib;
            inherit coreScriptDeps;
            dotnet-aspnetcore_9 = pkgs'.dotnet-aspnetcore_9;
          };

          packages = {
            # Primary entry for consuming the installer from another flake / on any device.
            spt-additions = sptAdditions;

            # The server launcher (with desktop entry).
            spt-server = sptServer;

            # The client/launcher (SPT.Launcher.exe via Proton/umu).
            spt-launcher = sptLauncher;

            # Default to the server launcher for `nix run .` convenience.
            default = sptServer;
          };

          # Explicit `apps` entries make `nix run .#spt-xxx` use the first-class
          # app definition rather than the packages fallback. This is the
          # recommended way to declare runnable commands in flakes.
          apps = {
            spt-additions = {
              type = "app";
              program = lib.getExe self'.packages.spt-additions;
            };
            spt-server = {
              type = "app";
              program = lib.getExe self'.packages.spt-server;
            };
            spt-launcher = {
              type = "app";
              program = lib.getExe self'.packages.spt-launcher;
            };
          };
        };

      # Modules for easy consumption in personal flakes / home-manager / NixOS configs.
      # Example usage in your own flake:
      #
      #   inputs.spt-linux-guide.url = "github:rykugur/SPT-Linux-Guide";
      #
      #   # Option 1: use the overlay (then packages are available in pkgs)
      #   nixpkgs.overlays = [ inputs.spt-linux-guide.overlays.default ];
      #
      #   homeConfigurations.you = ... {
      #     modules = [
      #       inputs.spt-linux-guide.homeModules.spt
      #       {
      #         programs.spt = {
      #           enable = true;
      #           server.enable = true;
      #           launcher.enable = true;
      #
      #           # Use lib.mkSptMods for the flake's supported SPT version.
      #           # Dependencies are automatically resolved and included.
      #           let
      #             spt = inputs.spt-linux-guide;
      #           in
      #           {
      #             mods = with (spt.lib.mkSptMods pkgs spt.supportedSptVersion); [
      #               uifixes
      #               sain  # pulls in bigbrain + waypoints automatically
      #             ];
      #           };
      #         };
      #       }
      #     ];
      #   };
      #
      #   # Option 2: explicitly pass packages (no overlay needed)
      #   # programs.spt.package = inputs.spt-linux-guide.packages.${pkgs.system}.spt-additions;
      #   # etc.
      flake = {
        overlays.default = final: _prev: {
          spt-additions = self.packages.${final.system}.spt-additions;
          spt-server = self.packages.${final.system}.spt-server;
          spt-launcher = self.packages.${final.system}.spt-launcher;
          sptMods = self.lib.mkSptMods final self.supportedSptVersion;
        };

        lib = {
          inherit (spt) mkSptMod mkSptMods supportedSptVersion sptModVersions;
        };

        homeModules = {
          spt = import ./nix/modules/home-manager/spt.nix;
          default = self.homeModules.spt;
        };

        # nixosModules.default = ...;  # can be added later if needed
      };
    };
}
