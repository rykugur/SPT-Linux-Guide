{
  description = "Development environment for SPT-Linux-Guide (spt-additions script + NixOS testing)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      imports = [
        inputs.devenv.flakeModule
      ];

      perSystem = { config, pkgs, lib, system, ... }: {
        # Dev shell using devenv (user's preferred tool)
        devenv.shells.default = {
          name = "spt-linux-guide";

          packages = with pkgs; [
            # --- Core dependencies for spt-additions ---
            umu-launcher          # umu-run for the script
            steam-run             # FHS wrapper (critical for NixOS testing of umu)
            jq
            unixtools.xxd
            hdiffpatch            # provides hpatchz
            python3
            curl
            p7zip                 # we provide 7zzs below for script compatibility

            # Linux server runtime
            dotnet-aspnetcore_9

            # --- Development / debugging tools ---
            shellcheck
            shfmt
            git
            just
            file
            which
            tree

            # Custom 7zzs so the script's `command -v 7zzs` and `m_7z` succeed
            # without triggering the auto-downloader every time.
            (pkgs.runCommand "7zzs" { } ''
              mkdir -p $out/bin
              ln -s ${lib.getExe p7zip} $out/bin/7zzs
            '')
          ];

          # Make sure the script can find things the way it expects on NixOS
          env = {
            # The script already detects /etc/NIXOS + steam-run and wraps automatically,
            # but we can hint here too.
            SPT_DEV = "1";
          };

          enterShell = ''
            echo "SPT Linux Guide development shell"
            echo "=================================="
            echo ""
            echo "Tools available for the script:"
            echo "  umu-run:     $(command -v umu-run || echo 'not found')"
            echo "  7zzs:        $(command -v 7zzs || echo 'not found')"
            echo "  steam-run:   $(command -v steam-run || echo 'not found')"
            echo "  hpatchz:     $(command -v hpatchz || echo 'not found')"
            echo "  jq / xxd:    $(command -v jq) / $(command -v xxd)"
            echo "  dotnet (for server): $(command -v dotnet || echo 'not in PATH, use DOTNET_ROOT')"
            echo ""
            echo "Useful commands:"
            echo "  ./scripts/spt-additions --help"
            echo "  ./scripts/spt-additions --no-ansi version"
            echo "  just --list"
            echo ""
            echo "NixOS-specific testing:"
            echo "  The script should now auto-wrap with steam-run when it detects NixOS."
            echo "  You can force/test the path with: steam-run ./scripts/spt-additions ..."
            echo ""
          '';

          # Optional: basic tests the shell provides the expected tools
          enterTest = ''
            echo "Checking required tools..."
            command -v umu-run >/dev/null
            command -v 7zzs >/dev/null
            command -v jq >/dev/null
            command -v xxd >/dev/null
            command -v hpatchz >/dev/null
            command -v steam-run >/dev/null
            echo "All core tools present."
          '';
        };

        # Also expose a plain mkShell as devShells.default for people who don't use devenv
        devShells.default = config.devenv.shells.default;
      };
    };
}
