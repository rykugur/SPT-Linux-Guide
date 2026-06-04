{
  description = "SPT-Linux-Guide: tools and launchers for running SPTarkov on Linux, with strong NixOS support. Usable as a flake input for dev shells, wrapped scripts, and (future) modules.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, self, ... }:
    let
      supportedSptVersion = "4.0.13";

      # Map from SPT version to the mod info (version, url, hash, optional dependencies list).
      # Update this manually when bumping the supported SPT version.
      # Each entry uses the lib.mkSptMod under the hood to create the package.
      sptModVersions = {
        "4.0.13" = {
          uifixes = {
            version = "5.3.9";
            url = "https://github.com/tyfon7/UIFixes/releases/download/v5.3.9/Tyfon-UIFixes-5.3.9.zip";
            hash = "sha256-17pkai6lyzwr7q8124vhq20zv45py34m5627krhh9xvj49k88cv3";
          };
          bigbrain = {
            version = "1.4.0";
            url = "https://github.com/DrakiaXYZ/SPT-BigBrain/releases/download/1.4.0/DrakiaXYZ-BigBrain-1.4.0.7z";
            hash = "sha256-0y9hzbbgnfqd5b8lgh8lifzak2h5iak778pbk08258782klzk384";
          };
          waypoints = {
            version = "1.8.2";
            url = "https://github.com/DrakiaXYZ/SPT-Waypoints/releases/download/1.8.2/DrakiaXYZ-Waypoints-1.8.2.7z";
            hash = "sha256-17siqdnyjsf7cl8qh9djmgbh9vq197mq1wwvlk1hiyvsvh35z1gl";
          };
          sain = {
            version = "4.4.3";
            url = "https://github.com/ArchangelWTF/SAIN/releases/download/v4.4.3/SAIN.4.4.3.zip";
            hash = "sha256-03iwalv2byvypymvmbrpk4pk518rhdjybp6ny8iasqp4gca2rap9";
            dependencies = [ "bigbrain" "waypoints" ];
          };
        };
        # Add future SPT versions here, e.g.
        # "4.1.0" = { ... updated mod versions for 4.1.0 ... };
      };

      mkSptMod = { pkgs, pname, version, url, hash, dependencies ? [], homepage ? "https://github.com/${pname}" }:
        pkgs.stdenv.mkDerivation {
          inherit pname version;
          src = pkgs.fetchurl { inherit url hash; };
          dontUnpack = true;
          nativeBuildInputs = with pkgs; [ p7zip gnutar gzip bzip2 xz ];
          installPhase = ''
            mkdir -p $out
            case "$src" in
              *.zip|*.7z)
                7zz x "$src" -o$out
                ;;
              *.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz)
                tar -xf "$src" -C $out
                ;;
              *)
                echo "Unsupported archive type for $src"
                exit 1
                ;;
            esac
          '';
          passthru = {
            inherit dependencies;
          };
          meta = {
            description = "SPT mod: ${pname}";
            inherit homepage;
          };
        };

      mkSptMods = pkgs: sptVersion:
        let
          l = pkgs.lib;
          vers = sptModVersions.${sptVersion} or (throw "No mod versions defined for SPT ${sptVersion}. Supported versions: ${l.concatStringsSep ", " (l.attrNames sptModVersions)}");
          base = l.mapAttrs (pname: info:
            mkSptMod {
              inherit pkgs pname;
              inherit (info) version url hash;
            }
          ) vers;
          final = l.mapAttrs (pname: info:
            let
              depNames = info.dependencies or [];
              deps = map (d: final.${d}) depNames;
            in
              base.${pname} // {
                passthru = (base.${pname}.passthru or {}) // { dependencies = deps; };
              }
          ) vers;
        in final;
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

          # Distributable `spt-server` command + .desktop for launching the native
          # SPT.Server.Linux. Provides a hermetic DOTNET_ROOT.
          #
          # Usage (standalone or as flake input):
          #   nix run github:MadByteDE/SPT-Linux-Guide#spt-server
          #   # or after adding the package:
          #   spt-server
          #
          # Also ships a .desktop entry so it appears in menus.
          spt-server =
            let
              serverScript = pkgs'.writeShellScriptBin "spt-server" ''
                set -euo pipefail

                export DOTNET_ROOT="${pkgs'.dotnet-aspnetcore_9}/share/dotnet"

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
            pkgs'.symlinkJoin {
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
                cp ${./media/coverart/apps/lutris_sptarkov-server.png} \
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
            };

          # The additions installer script, wrapped so that `nix run ...#spt-additions`
          # (or when consumed from another flake) has its native dependencies available.
          # This is the key entrypoint for "run the installer on any Nix machine".
          # We also pull in spt-server so that `spt-additions run server` can prefer
          # the reliable direct launcher when available (very useful under `nix run`).
          spt-additions = pkgs'.writeShellApplication {
            name = "spt-additions";
            runtimeInputs = coreScriptDeps ++ [ spt-server ];
            text = ''
              export DOTNET_ROOT="${pkgs'.dotnet-aspnetcore_9}/share/dotnet"
              exec ${./scripts/spt-additions} "$@"
            '';
            meta = {
              description = "The SPT-Linux-Guide additions installer (native Linux path using umu/GE-Proton).";
              homepage = "https://github.com/MadByteDE/SPT-Linux-Guide";
              license = lib.licenses.mit;
              mainProgram = "spt-additions";
            };
          };

          # Convenience launcher for the SPT client/launcher (SPT.Launcher.exe).
          # This is the GUI you use to start the game (after the server is running).
          # It delegates to the additions script's "run launcher" logic so it gets
          # the correct umu-run (with steam-run wrapper on NixOS) and prefix setup.
          spt-launcher = pkgs'.writeShellApplication {
            name = "spt-launcher";
            runtimeInputs = [ spt-additions ];
            text = ''
              exec spt-additions run launcher "$@"
            '';
            meta = {
              description = "Launch the SPTarkov client/launcher (SPT.Launcher.exe via umu/Proton).";
              longDescription = ''
                Requires that you have previously installed SPT using spt-additions
                (or the Lutris installer). It will use the same install location
                discovery as the other tools.

                This is equivalent to running `spt-additions run launcher` but
                exposed as a first-class command for convenience when using
                this flake as an input.
              '';
              homepage = "https://github.com/MadByteDE/SPT-Linux-Guide";
              license = lib.licenses.mit;
              mainProgram = "spt-launcher";
            };
          };
        in
        {
          # Development shell for working on the guide itself (especially the spt-additions script
          # and NixOS-specific paths). Provides every tool the script expects plus dev helpers.
          devShells.default = pkgs'.mkShell {
            packages = with pkgs'; [
              # Core script runtime (duplicated from coreScriptDeps for the shell experience)
              umu-launcher
              steam-run
              jq
              unixtools.xxd
              python3
              curl
              p7zip
              (pkgs'.runCommand "7zzs" { } ''
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
              DOTNET_ROOT = "${pkgs'.dotnet-aspnetcore_9}/share/dotnet";
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
          };

          packages = {
            # Primary entry for consuming the installer from another flake / on any device.
            inherit spt-additions;

            # The server launcher (with desktop entry).
            inherit spt-server;

            # The client/launcher (SPT.Launcher.exe via Proton/umu).
            inherit spt-launcher;

            # Default to the server launcher for `nix run .` convenience.
            default = spt-server;
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
          inherit mkSptMod mkSptMods supportedSptVersion sptModVersions;
        };

        homeModules = {
          spt = import ./modules/home-manager/spt.nix;
          default = self.homeModules.spt;
        };

        # nixosModules.default = ...;  # can be added later if needed
      };
    };
}
