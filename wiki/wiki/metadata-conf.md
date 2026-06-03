# metadata.conf

Configuration file with URLs and hashes for downloads, SPT releases, tools, and icons.

**Raw source**: [[raw/metadata.conf]]

## Contents (as of current)
- `additions-hash`, legacy patcher/SPT hashes and URLs.
- Tool download URLs: umu-run, 7zzs (current 26.01), hpatchz, jq, xxd (via deb), GE-Proton releases.
- BSG launcher, SPTInstaller.exe, dotnet Windows runtimes (for prefix), icon URLs.
- Live metadata: `patcher-json-url`, `mod-json-url` (for latest SPT 4.x via jq), Fika GitHub release APIs, forge, discord, guide repo.
- `server-script-url` (for the launch-server.sh copy).

## Role in the Script
- Loaded early with TTL (7 days for metadata).
- Used by `load_metadata()` for `latest` (parses release.json and mirrors.json) and legacy.
- `install_dep`, `m_download`, `update_proton`, `check_hash`, self-update all pull from here.
- `METADATA_URL` points back to the raw file in the repo for self-updates.

## NixOS Relevance
- On NixOS you will often already have many of the "downloadable" tools (umu-run, jq, xxd) from nixpkgs via your gaming profile. The script will still consult the URLs if `command -v` fails.
- The 7zzs download is the standalone 7zip; your `pkgs.p7zip` or custom fetch7zip may provide `7z` instead.
- Hashes ensure integrity of downloaded archives/patchers even when on immutable systems.

## Related
- [[spt-additions-script]] (load_metadata, check_cached, install paths).
- [[dep-management]].
- [[raw/session-2026-06-03-nixos-implementation.md]] (how deps interact with NixOS).
