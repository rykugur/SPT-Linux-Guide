# SPT mod support for the flake.
# Defines the current supported SPT version, the version map for mods,
# and helpers to build individual mod packages (with dep resolution).
#
# Usage:
#   let spt = import ./nix/spt-mods.nix { lib = pkgs.lib; }; in
#   spt.mkSptMods pkgs   # -> { uifixes = <drv>; sain = <drv>; ... }
#
# Or for a specific version:
#   spt.mkSptMods pkgs "4.0.13"

{ lib }:

rec {
  supportedSptVersion = "4.0.13";

  # Map from SPT version to mod info.
  # Update this (and supportedSptVersion) when a new SPT version is the default.
  # Each mod can declare `dependencies = [ "other" "mods" ];` (names, resolved later).
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
    # Example for future:
    # "4.1.0" = {
    #   uifixes = { version = "5.4.0"; url = "..."; hash = "..."; };
    #   ...
    # };
  };

  # Creates a single mod package from a release archive.
  # The resulting derivation's $out contains the BepInEx/ and/or SPT/ tree(s)
  # ready to be merged into a user's SPTarkov install.
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

  # Builds the attrset of all mods for a given SPT version, resolving the
  # dependency graph (transitive closure, deps first).
  # Returns e.g. { uifixes = <drv>; bigbrain = <drv>; sain = <drv with passthru.dependencies>; ... }
  mkSptMods = pkgs: sptVersion:
    let
      l = pkgs.lib;
      vers = sptModVersions.${sptVersion} or (throw "No mod versions defined for SPT ${sptVersion}. Supported versions: ${l.concatStringsSep ", " (l.attrNames sptModVersions)}");
      base = l.mapAttrs (pname: info:
        (mkSptMod {
          inherit pkgs pname;
          inherit (info) version url hash;
        })
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
}
