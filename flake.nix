{
  description = "SPT-Linux-Guide: spt-additions, spt-server, and spt-launcher for running SPTarkov on Linux (with strong NixOS support via umu/steam-run).";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { flake-parts, self, ... }@inputs:
    let
      # Helpers for the runnable tools only. This flake concerns itself solely
      # with exposing the launchers/installer (and a dev shell). Mod builders,
      # version maps, and the Home Manager module now live in personal config
      # flakes that import this one.
      spt = import ./nix { lib = inputs.nixpkgs.lib; };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { pkgs, system, lib, ... }:
        let
          pkgs' = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          sptPkgs = spt.mkSptPackages pkgs' lib;
        in
        {
          devShells.default = import spt.devshell { pkgs = pkgs'; inherit lib; };

          packages = sptPkgs;

          apps = {
            spt-additions = { type = "app"; program = lib.getExe sptPkgs.spt-additions; };
            spt-server    = { type = "app"; program = lib.getExe sptPkgs.spt-server; };
            spt-launcher  = { type = "app"; program = lib.getExe sptPkgs.spt-launcher; };
          };
        };

      flake = {
        # Overlay only provides the three runnable tools. Mods (sptMods) and
        # the home-manager module are no longer part of this flake's public API.
        overlays.default = final: _prev: {
          spt-additions = self.packages.${final.system}.spt-additions;
          spt-server    = self.packages.${final.system}.spt-server;
          spt-launcher  = self.packages.${final.system}.spt-launcher;
        };
      };
    };
}
