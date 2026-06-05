# SPT mod support (reference implementation).
#
# NOTE: As of recent changes, this file and its builders are **no longer part
# of the public flake outputs** of SPT-Linux-Guide. The flake only exposes the
# runnable tools (spt-additions, spt-server, spt-launcher).
#
# The logic is kept here as a reference / starting point for you to vendor into
# your personal configuration flake (e.g. ~/.dotfiles), where you can maintain
# your own supportedSptVersion + mod map and expose it via your own lib / modules.
#
# Previous usage (no longer provided by this flake):
#   let spt = import ./nix { lib = pkgs.lib; }; in
#   spt.mkSptMods pkgs   # -> { uifixes = <drv>; sain = <drv>; ... }

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
        hash = "sha256-YzOEZiJy9wRhnkeYUsnwt5D9gcBwExEQPpl/T01U854=";
      };
      bigbrain = {
        version = "1.4.0";
        url = "https://github.com/DrakiaXYZ/SPT-BigBrain/releases/download/1.4.0/DrakiaXYZ-BigBrain-1.4.0.7z";
        hash = "sha256-BI356RTooCIQmOuic6aKBYqpvosUwUfRKg07+9b6MHk=";
      };
      waypoints = {
        version = "1.8.2";
        url = "https://github.com/DrakiaXYZ/SPT-Waypoints/releases/download/1.8.2/DrakiaXYZ-Waypoints-1.8.2.7z";
        hash = "sha256-9IVfBtx6+wjDpJvzgOtJAe8E16uyJYgRZcdp6W3DUZ8=";
      };
      sain = {
        version = "4.4.3";
        url = "https://github.com/ArchangelWTF/SAIN/releases/download/v4.4.3/SAIN.4.4.3.zip";
        hash = "sha256-6aosFHvkYq0i8tbc5WWDGYUyL5k3r7qrv377JTZVPA4=";
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
      nativeBuildInputs = with pkgs; [ _7zz gnutar gzip bzip2 xz ];
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
