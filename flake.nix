{
  description = "SPT-Linux-Guide: tools and launchers for running SPTarkov on Linux, with strong NixOS support. Usable as a flake input for dev shells, wrapped scripts, and (future) modules.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { flake-parts, self, ... }@inputs:
    let
      # Import once (pure, only needs nixpkgs.lib). Gives mod helpers + mkCoreScriptDeps +
      # mkSptPackages + modules paths etc. This (plus the tiny perSystem below) is why
      # flake.nix can stay short and sweet.
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

          legacyPackages = {
            # Mods live here (not under `packages` because flake-parts types
            # `packages.*` as single derivations). This lets you do:
            #   nix build .#legacyPackages.x86_64-linux.sptMods.sain
            # which gives you a convenient `result` symlink without needing
            # the full /nix/store/... hash upfront.
            sptMods = spt.mkSptMods pkgs' spt.supportedSptVersion;
          };

          apps = {
            spt-additions = { type = "app"; program = lib.getExe sptPkgs.spt-additions; };
            spt-server    = { type = "app"; program = lib.getExe sptPkgs.spt-server; };
            spt-launcher  = { type = "app"; program = lib.getExe sptPkgs.spt-launcher; };
          };
        };

      flake = {
        overlays.default = final: _prev: {
          spt-additions = self.packages.${final.system}.spt-additions;
          spt-server    = self.packages.${final.system}.spt-server;
          spt-launcher  = self.packages.${final.system}.spt-launcher;
          sptMods       = self.lib.mkSptMods final self.lib.supportedSptVersion;
        };

        lib = {
          inherit (spt) mkSptMod mkSptMods supportedSptVersion sptModVersions;
        };

        homeModules = {
          spt = spt.modules.homeManager;
          default = self.homeModules.spt;
        };

        # nixosModules.default = ...;  # future
      };
    };
}
