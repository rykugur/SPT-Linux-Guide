# NixOS Support

**Status (post this session)**: Docs improved + script has basic awareness + steam-run auto-wrap (UMU_CMD) when available. README warning softened to informative NOTE. Wiki fully bootstrapped per llm-wiki skill (from dotfiles/modules/ai/skills/llm-wiki) and used to drive the changes. Full end-to-end user testing on real installs still needed. See "Changes Landed" section below + the raw session source.

**Status (pre this session)**: Partial / community-workaround only. Official warning in README links to stalled PR #14. Goal of current work: make `spt-additions` (native path) and docs "just work" with reasonable NixOS config + minimal script tweaks. Remove or heavily qualify the warning.

## Changes Landed (this WORK session)
- docs/aspnet.md: Full Nixpkgs install + DOTNET_ROOT guidance (with verification commands).
- README.md: Warning -> helpful NOTE with links to aspnet + this wiki page + PR.
- spt-additions: 
  - NixOS detection + auto `UMU_CMD="steam-run ..."` (affects m_umu and key direct calls).
  - Helpful messages in check_native_deps + check_aspnet when on /etc/NIXOS.
  - UMU_CMD mechanism for future extensions.
- Dev environment: Added `flake.nix` + `devenv.nix` + `justfile` (and .envrc) so you get all the script's native tools reproducibly, including `steam-run` for easy FHS wrapper testing. See the "Development" section in the main README.
- This wiki: Full bootstrap of llm-wiki (raw/ + wiki/ + schema + index + log), multiple entity/concept/platform pages written during research/ingest/synthesis. (See log.md for details.)

Remaining (tracked in project todos / future sessions): more test coverage, .desktop shortcut handling, additional direct UMU_PATH sites, user reports, perhaps explicit `--fhs` flag or env, updating legacy notes, etc.

## Why It's Hard (FHS & Containers)
NixOS stores everything in `/nix/store/...` with explicit dependencies. No global `/lib`, `/usr/lib`, `/etc/ld.so.cache` in the traditional sense.

`umu-launcher` (used heavily by the script for running Windows exes under Proton/GE without full Lutris) internally uses **pressure-vessel** (a Steam runtime container tool) + bubblewrap. These expect an FHS environment for the containerized app's dynamic linker and libs.

Result when running plain on NixOS:
- "BadMatch" or missing lib errors, or silent failures inside the container.
- The `SPT.Server.Linux` native binary (post-install) can also have issues if its .NET deps aren't discoverable.

**Common successful workaround** (from PR #14 and user's setup):
- Use `steam-run` (provides a full Steam FHS userland) to launch tools that need it: `steam-run umu-run ...` or wrap the entire script invocation.
- Or rely on Lutris (which user's modules pre-configure with forced nixpkgs umu + proton-ge).

User's dotfiles (see [[raw/nixos-gaming-setup]]) already do a lot of the heavy lifting:
- `umu-launcher` package + forced symlink into Lutris runtime.
- `proton-ge-bin` for Lutris and Steam.
- `unixtools.xxd`, winetricks, etc. in gaming profile.
- Steam with extraCompatPackages.

## Required Configuration for Users (Minimal Working Set)

### 1. ASP.NET for the Linux Server
The `SPT/SPT.Server.Linux` binary is a .NET 9 app. On Nix it won't find the runtime unless told where.

Add to your system config (or home-manager):
```nix
# configuration.nix or a module
environment.sessionVariables = {
  DOTNET_ROOT = "${pkgs.dotnet-aspnetcore_9}/share/dotnet/";
};
```
(or `home.sessionVariables` if using HM only).

**Current package attribute** (as of this host NixOS 26.05 / nixpkgs):
- `pkgs.dotnet-aspnetcore_9` (resolves; provides wrapped runtime)
- Also available as `dotnetCorePackages.aspnetcore_9_0`

After rebuild + re-login (for session var), the server should see .NET.

The script itself has `check_aspnet()` which runs `dotnet --list-runtimes | grep AspNet | grep 9.0`. This may pass once the package + DOTNET_ROOT is set (or `dotnet` from the package is in PATH).

**Note from PR commit 9057d90** (never fully landed on main): Recommended `dotnet-aspnetcore_9` in `environment.systemPackages` or `home.packages`. The sessionVariables part came from user reports.

### 2. Native Dependencies the Script Expects
`check_native_deps` requires (and will auto-download some to `~/.local/share/spt-additions/runtime` if missing):
- python3, curl (usually present)
- 7zzs (the 7zip standalone; `p7zip` pkg gives `7z`; script downloads the ip7z release if `7zzs` not found)
- xxd (provided by `unixtools.xxd` in user's gaming profile)
- hpatchz (from hdiffpatch; script downloads)
- jq (present)
- umu-run (present via user's modules)

On NixOS, prefer letting nix provide them rather than the script's downloaders when possible (avoids duplicating binaries and potential lib mismatches).

In `~/.config/spt-additions/` or via command line, users can set envs.

### 3. Running the Native Installer (spt-additions)
Options that have worked in reports:
- `steam-run bash -c 'spt-additions ...'` (wraps the whole thing in FHS env from Steam).
- Or patch the script temporarily to prefix m_umu calls.
- Install via the Lutris additions YAML (many report this "just works" once dotnet root is set and pre-launch script disabled for the launcher entry).

After install, the client runs via the Proton prefix created by umu. The server is the native Linux one.

### 4. Lutris-Specific on NixOS
From matt-harp in PR:
- Disable the pre-launch script in the SPTarkov - Launcher Lutris entry (System options > Pre-launch script).
- Create separate native entry for the server binary or use launch-server.sh with a real terminal (not under Wine).

User's lutris module already forces the correct umu-run.

### 5. Other Gotchas
- Self-install of the script (`spt-additions self-install`): Puts it in ~/.local/bin or similar. Ensure that is in PATH. One report said "everything installed correctly except the spt-additions cli".
- Hash checks and downloads: Should be fine (curl + 7z).
- Prefix location: Default ~/Games/tarkov – writable in home.
- When updating metadata or using live JSON for SPT 4.x, no special issues expected.
- Audio / perf / in-raid issues are general Linux (see issues.md); NixOS kernel (zen in user's setup) + mesa (chaotic or stock) can be advantages.

## Script Changes That Would Help (Proposed)
See related entity pages and future edits:
- Detect NixOS (`[[ -e /etc/NIXOS ]]`).
- If `umu-run` missing but `steam-run` present, set UMU_PATH or wrap m_umu with it (or warn + suggest).
- In check_aspnet and install messages, emit NixOS-specific advice about sessionVariables and the package.
- Better messaging when auto-downloading tools that are better provided by nix.
- Document `spt-additions run ...` under steam-run.
- Possibly a `--nixos` mode or env var `SPT_NIXOS=1`.

Longer term: A proper `sptarkov` package in nixpkgs or user's pkgs/ would be nice but is a lot of work (bundling the whole EFT+SPT, handling updates/patchers, server, launchers). Guide + script improvements are the practical first step.

## Current Host Testing Notes (this machine)
- Is NixOS 26.05 (BUILD_ID 26.05.20260523...).
- Has `jq`, `umu-run` in user profile.
- 7zzs: not in base PATH (script will want to download or user can `nix-shell -p p7zip` or install 7zip pkg).
- dotnet-aspnetcore_9 attribute available.
- Full gaming profile from dotfiles not necessarily activated in this shell context, but packages can be pulled ad-hoc.

## References & Sources
- Raw: [[raw/pr-14-nixos-discussion.md]]
- Raw: [[raw/nixos-gaming-setup.md]]
- Raw: [[raw/session-2026-06-03-nixos-implementation.md]] (this implementation session + exact diffs made)
- Project: README (softened note), docs/aspnet.md (Nixpkgs section added), scripts/spt-additions (NixOS detection + UMU_CMD wrapper + messaging)
- Script internals: check_native_deps, m_umu (now uses UMU_CMD), UMU_PATH resolution, check_aspnet, init_prefix paths, direct umu calls for BSG.
- External: NixOS wiki on steam-run / FHS, umu-launcher packaging in nixpkgs, dotnetCorePackages in nixpkgs.

**Next actions tracked in project todos**: Update aspnet.md, qualify README, script enhancements for detection/wrappers, actual test runs here, wiki synthesis.
