{
  description = "Development environment for SPT-Linux-Guide (spt-additions bash script, with focus on NixOS support)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in {
      devShells = forEachSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;  # steam-run (and potentially others) are unfree
          };
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # === Tools the spt-additions script expects ===
              umu-launcher      # umu-run
              steam-run         # FHS wrapper – essential for testing the NixOS auto-wrap logic
              jq
              unixtools.xxd
              # hpatchz/hdiffpatch: the script auto-downloads it via install_dep if missing.
              # Adding here is optional; we omit to avoid attr hunting.
              python3
              curl
              p7zip

              # Provide `7zzs` exactly as the script looks for it (avoids auto-download in dev)
              (pkgs.runCommand "7zzs" { } ''
                mkdir -p $out/bin
                ln -s ${lib.getExe p7zip} $out/bin/7zzs
              '')

              # For the native Linux server (SPT.Server.Linux)
              dotnet-aspnetcore_9

              # === Development helpers ===
              shellcheck
              shfmt
              git
              just
              file
              which
              tree

              # For winetricks (used by the script for dotnet48, vcrun etc.)
              winetricks
              cabextract
            ];

            env = {
              # Required for the native SPT.Server.Linux .NET app to find its runtime on NixOS
              DOTNET_ROOT = "${pkgs.dotnet-aspnetcore_9}/share/dotnet";
            };

            shellHook = ''
              echo "SPT Linux Guide dev shell"
              echo "=========================="
              echo ""
              echo "Script dependencies:"
              echo "  umu-run:   $(command -v umu-run || echo 'MISSING')"
              echo "  7zzs:      $(command -v 7zzs || echo 'MISSING')"
              echo "  steam-run: $(command -v steam-run || echo 'MISSING')"
              echo "  jq / xxd : $(command -v jq || echo 'MISSING') / $(command -v xxd || echo 'MISSING')"
              echo ""
              echo "NixOS note: The script auto-detects /etc/NIXOS + steam-run and wraps umu-run for FHS."
              echo "            Force/test the path explicitly with: steam-run ./scripts/spt-additions ..."
              echo ""
              echo "Try: just --list   (or just check / just version)"
              echo ""
              echo "DOTNET_ROOT for server: $DOTNET_ROOT"
            '';
          };
        }
      );
    };
}
