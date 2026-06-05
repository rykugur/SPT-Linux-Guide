# This is a standalone devenv.nix you can use with `devenv` (if you prefer the full
# devenv experience over the simple mkShell in flake.nix).
#
# To use it:
#   1. Make sure you have devenv installed
#   2. `devenv shell` (or configure direnv to use it)
#
# For the integrated flake experience, the flake.nix + mkShell above is recommended
# and guaranteed to work without directory detection issues.

{ pkgs, lib, config, inputs, ... }:

{
  name = "spt-linux-guide";

  packages = [
    pkgs.umu-launcher
    pkgs.steam-run
    pkgs.jq
    pkgs.unixtools.xxd
    pkgs.hdiffpatch
    pkgs.python3
    pkgs.curl
    pkgs.p7zip
    (pkgs.runCommand "7zzs" { } ''
      mkdir -p $out/bin
      ln -s ${lib.getExe pkgs.p7zip} $out/bin/7zzs
    '')
    pkgs.dotnet-aspnetcore_9

    pkgs.shellcheck
    pkgs.shfmt
    pkgs.just
  ];

  env.SPT_DEV = "1";

  enterShell = ''
    echo "SPT Linux Guide (full devenv)"
  '';
}
