# SPT Linux Guide Wiki - Index

**Purpose**: Starting point for any query or work. Read this first. LLM keeps it updated on ingests.

## Overview & Meta
- [[WIKI]] - Schema, conventions, and instructions for maintaining this wiki.
- [[log]] - Full chronological history of changes to the knowledge base.

## Core Entities
- [[spt-additions-script]] - The main 2200-line bash installer. CLI surface, flows (install/update/run/etc.), dep management, umu/proton integration, legacy vs latest modes, Fika support, shortcuts, patching.
- [[launch-server-script]] - Small pre-launch helper for Lutris/official installs. Terminal discovery + flatpak-spawn handling for server.
- [[metadata-conf]] - URLs, hashes, versions for tools, SPT archives, patchers, icons. Live vs pinned (legacy).

## Installation Methods
- [[native-umu-install]] - Primary modern path using umu-run + GE-Proton directly (no Lutris/Bottles required for client).
- [[lutris-additions]] - Lutris installer using the additions script (`-m lutris`).
- [[lutris-official]] - Uses official SPTInstaller.exe via Wine in Lutris.
- [[bottles-manual]] - Unsupported manual Bottles path.
- [[proton-direct]] - `install proton` mode (legacy?).

## Platform Support
- [[nixos-support]] - Status after 2026-06-03 implementation: basic detection + steam-run UMU wrapper landed in script, docs updated (aspnet + README), wiki used for synthesis. Still needs broader user testing. Links to raw PR + session notes + dotfiles.
- General Linux assumptions in script (PATH tools, writable ~/.local, etc.).

## Key Concepts & Internals
- [[dep-management]] - Native tools (7zzs, jq, hpatchz, xxd, umu-run, python3, curl) + auto-download fallbacks in `check_native_deps` + `install_dep`.
- [[fhs-and-containers]] - Why umu/pressure-vessel is sensitive on immutable/FHS-less systems like NixOS (and the steam-run mitigation now in the script).
- [[dotnet-for-server]] - Why native Linux SPT server needs aspnetcore-runtime-9 on host + DOTNET_ROOT.
- [[install-modes]] - `latest`, `legacy`, `proton`, `lutris` and their special paths in code.
- [[patching-flow]] - Downpatching EFT files using hpatchz + SPT_Patches when EFT version mismatch.
- [[shortcuts-and-env]] - .desktop creation, env.conf, config persistence.

## Sources Ingested
- Project README, all docs/*.md, scripts/* (via symlinks in raw/).
- PR #14 full discussion (raw/pr-14-nixos-discussion.md).
- User's dotfiles gaming + AI modules (raw/nixos-gaming-setup.md).
- 2026-06-03 implementation session itself (raw/session-2026-06-03-nixos-implementation.md) — the exact changes, rationale, and wiki-driven workflow.

## Planned / Stub Pages (referenced but not yet created as full pages)
These are listed in the schema/index for completeness; create on next relevant query or ingest:
- [[native-umu-install]]
- [[lutris-additions]]
- [[lutris-official]]
- [[bottles-manual]]
- [[proton-direct]]
- [[install-modes]]
- [[patching-flow]]
- [[shortcuts-and-env]]

_Last updated: 2026-06-03 (lint + new session ingest; see log.md)._
_Add new pages here as they are created._
