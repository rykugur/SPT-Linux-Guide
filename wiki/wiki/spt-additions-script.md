# spt-additions Script

**The heart of the modern install experience.** Standalone ~2200 LOC MIT bash script. Replaces/augments Lutris/Bottles for many users. Version in code: 1.1.7 (2026-05-12).

**Raw source**: [[raw/spt-additions.sh]] (symlink to scripts/spt-additions in repo)

## High-Level Architecture
- **Config / State**: XDG dirs under `~/.local/share/spt-additions/`, `~/.config/spt-additions/`, cache in `~/.cache/spt-additions/`.
  - `app.conf`, `env.conf` persisted via `save_array`/`load_array`.
  - `CONFIG[]`, `ENV[]`, `METADATA[]` associative arrays.
- **Wrappers**: `m_*` functions (m_umu, m_7z using 7zzs, m_curl, m_cp with progress, m_extract, m_download with force/silent, m_rm with safety checks).
- **Safety**: Root check, target_path allowlist in `check_target_path`, path validation, disk space, running process checks, hash verification (md5 base64), TTL caching for metadata/downloads.
- **Prefix init**: `init_prefix` + `set_prefix_path`. Handles GE-Proton download if needed, wineboot, win81, BSG/EFT path detection (special case for Steam compatdata 3932890).
- **Install modes** (`-m`): `latest` (default, native SPT 4.x), `legacy` (3.11), `proton` (SPTInstaller.exe inside prefix), `lutris` (special path tweaks for Lutris YAML).

## Main CLI Surface (from opt_help)
- `install eft|spt|fika`
- `uninstall ...`
- `update spt|fika|proton|additions`
- `run eft|launcher|server|winecfg|winetricks|...`
- `env set|unset|list`
- `dlloverride`
- `shortcut`
- `patch` (manual downpatch)
- `clean`
- `self-install` / `self-update`
- Switches: `-p` prefix, `-e KEY=VAL`, `-m mode`, `--no-prompt`, `--no-ansi`

Guided install when run with no args.

## Critical Functions for Cross-Platform Work
- `check_native_deps`: Hard list `python3 curl 7zzs xxd hpatchz jq umu-run`. Missing downloadable ones go through `install_dep` (downloads from metadata urls to TMP then mv to RUNTIME_DIR, chmod +x).
- `m_umu`: The single point for all Proton/Wine execution. Currently just execs `${UMU_PATH}`. UMU_PATH falls back to downloaded umu-run zipapp if not in PATH.
- `check_aspnet`: Only warns (non-fatal) if `dotnet --list-runtimes` lacks AspNet 9.0. Used before SPT install. Important for Linux server post-install.
- `install_spt_native` + patch logic: Copies EFT, applies patcher if version mismatch (using hpatchz), extracts SPT 7z.
- `install_fika`: Fetches latest from GitHub API for core + server, version compatibility check against installed SPT-EFT.
- `add_battleye_workaround`: Registry hacks + file copy for BEService (common for anti-cheat under Wine).

## Assumptions That Bite on NixOS
- Commands like `7zzs`, `umu-run`, `xxd`, `jq`, `hpatchz` are either in $PATH or downloadable as static-ish binaries that "just work".
- `umu-run` can be executed directly and will create working containers (FHS expectation inside).
- `dotnet` on host PATH for server check + runtime discovery for `SPT.Server.Linux`.
- Writable home dirs for runtime, cache, icons, applications, prefixes.
- No special env for dynamic linker or container runtimes.

**Implemented mitigations (2026-06-03 session)**: NixOS detection (`/etc/NIXOS`), `UMU_CMD` wrapper using `steam-run` when available (affects `m_umu` and key direct calls), NixOS-specific guidance in `check_native_deps` and `check_aspnet`. See [[nixos-support]] and [[raw/session-2026-06-03-nixos-implementation.md]] for details and remaining work.

## Version & Self-Update
- Hardcoded VERSION/DATE.
- On run, if SCRIPT_PATH older than 5 days TTL, attempts `opt_selfupdate` (downloads from metadata[installer-script-url], hash check against additions-hash, mv+chmod).
- `self-install`: Moves/copies the script to a bin dir.

## Metadata
Live for latest SPT: mod-json-url, patcher-json-url (jq parsed for versions, urls, hashes).
Pinned in metadata.conf for legacy + all the tool download URLs (umu, 7zzs, hpatchz, jq, xxd deb, ge-proton, bsg launcher, spt installer, dotnet windows runtimes, icons, server-script, fika github apis).

## Related
- [[launch-server-script]]
- [[dep-management]]
- [[fhs-and-containers]]
- [[dotnet-for-server]]
- [[install-modes]]
- Raw metadata: [[raw/metadata.conf]]

**Maintenance note**: When editing the script, update this page + relevant concept pages + test on target platforms (including this wiki's host when possible).
