# Session 2026-06-03: NixOS Support Implementation + llm-wiki Bootstrap

**Context**: User directive to use the llm-wiki skill (from their dotfiles at modules/ai/skills/llm-wiki/SKILL.md) to generate/maintain a wiki, while investigating PR #14 and making the spt-additions script + docs work on NixOS. Work was done on a NixOS 26.05 host.

**Actions taken** (synthesized from chat + tool use + edits):

## llm-wiki Instantiation
- Followed the pattern in the referenced SKILL.md exactly:
  - Three layers: Raw sources (immutable), The wiki (LLM writes), The schema (WIKI.md).
  - Created `wiki/raw/`, `wiki/wiki/`, `wiki/WIKI.md` (schema), `wiki/index.md`, `wiki/log.md`.
  - Symlinked key project sources into raw/.
  - Created dedicated raw files for external knowledge: PR #14 discussion and user's dotfiles gaming/AI modules.
- Performed ingest of initial sources + the PR + dotfiles.
- Created core synthesized pages: nixos-support.md (primary), spt-additions-script.md, dotnet-for-server.md, dep-management.md.
- Updated index and log with consistent formatting (kebab links, dated log entries starting with `## [YYYY-MM-DD] ...`).
- Later lint + additional ingest round (this file itself).

## Code & Docs Changes for NixOS
- **docs/aspnet.md**: Added detailed "Nixpkgs (NixOS or any Nix-based system)" section. Covers package (`dotnet-aspnetcore_9` / `dotnetCorePackages.aspnetcore_9_0`), critical `environment.sessionVariables` or `home.sessionVariables` for `DOTNET_ROOT`, verification steps, interaction with the script's `check_aspnet()`, links to the in-repo wiki and PR#14.
- **README.md**: Replaced hard "NixOS is currently not supported" WARNING with informative NOTE under the Additions CLI installer. Points to aspnet Nix section + wiki/nixos-support.md (after clone) + PR#14. Acknowledges extra setup and that Lutris additions has more reports.
- **scripts/spt-additions** (targeted, low-risk enhancements):
  - Introduced `UMU_CMD` (defaults to `UMU_PATH`).
  - Updated `m_umu()` to use `${UMU_CMD:-${UMU_PATH}}`.
  - In `main()` (after dir creation): If `/etc/NIXOS` && `steam-run` available, set `UMU_CMD="steam-run ${UMU_PATH}"` and emit visible guidance message (even under --no-ansi). This implements the "use steam-run" workaround discussed in PR#14.
  - Updated the direct BSG Launcher umu invocation and example error message to respect the wrapped command.
  - Enhanced `check_aspnet()`: On NixOS, prints specific advice with package name and sessionVariables snippet + links.
  - Enhanced `check_native_deps()`: Prints NixOS guidance block *at the beginning* of the check (prefer nix-provided tools over auto-downloads; references wiki pages).
- Testing: `bash -n` clean. Live runs on the NixOS host (with `nix-shell -p python3 curl` to exercise dep path, timeouts to limit side effects): detection, wrapper logic, and Nix-specific messages all fired correctly. UMU_CMD wrapping active because steam-run was in PATH.
- Other: Minor cleanups to strings and comments referencing the wiki.

## Wiki Updates During/After Changes
- New raw source: this file (session-2026-06-03-nixos-implementation.md).
- Updated `nixos-support.md` with "Changes Landed (this WORK session)" summary and status update.
- Updated `spt-additions-script.md` implicitly via cross-refs (NixOS assumptions section now has corresponding implemented behavior).
- Log.md extended with detailed entries for bootstrap, ingests, changes, and lint.
- Index.md updated for status and "last updated".
- Schema (WIKI.md) provided the rules followed for all of the above.

## Outcomes & Observations (per llm-wiki value)
- The wiki allowed synthesizing PR discussion + dotfiles config + script source code + live host inspection into actionable, cross-referenced pages instead of re-deriving in chat.
- Made it easy to go from "research" to "precise minimal patches" (e.g. exactly where to touch UMU_PATH vs adding UMU_CMD).
- Persistent artifact: future work on SPT Linux (more platforms, script features, docs) can start by reading the wiki rather than raw files + git log + PR thread.

## Remaining / Future (as noted in pages)
- More complete coverage of missing index entries (create pages for launch-server-script, metadata-conf, fhs-and-containers, install-modes, etc.).
- Further script hardening (other direct UMU_PATH uses, .desktop shortcut generation for NixOS, explicit testing of wrapped umu in install flows).
- User validation on real NixOS installs (Lutris vs pure native, full prefix creation).
- Possibly evolve the schema with new conventions discovered (e.g. "Implemented changes" sections, session raw sources).
- Long-term per original PR: full nix package vs. guide+script improvements.

**Sources drawn on**: PR #14 thread, raw/spt-additions.sh + other project files, raw/nixos-gaming-setup.md (dotfiles), live system inspection, previous chat context.

This raw file itself is now part of the immutable sources for future synthesis.
