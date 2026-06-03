{ pkgs, lib, config, inputs, ... }:

{
  # This file is used when running `devenv` directly or as a module reference.
  # The main configuration lives in flake.nix (using devenv.flakeModule).

  packages = [
    # Re-declare here for `devenv shell` / `devenv up` workflows
    pkgs.umu-launcher
    pkgs.steam-run
    pkgs.jq
    pkgs.unixtools.xxd
    pkgs.hdiffpatch
    pkgs.python3
    pkgs.curl
    pkgs.p7zip

    # Provide 7zzs exactly as the script expects
    (pkgs.runCommand "7zzs" { } ''
      mkdir -p $out/bin
      ln -s ${lib.getExe pkgs.p7zip} $out/bin/7zzs
    '')

    pkgs.dotnet-aspnetcore_9

    # Dev tools
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.just
  ];

  env.SPT_DEV = "1";

  enterShell = ''
    echo "SPT Linux Guide (devenv)"
    echo "Run 'just --list' for common tasks (once added)."
  '';
}
