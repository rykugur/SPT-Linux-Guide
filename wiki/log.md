# SPT Linux Guide Wiki - Log

Append-only chronological record. Entries use `## [YYYY-MM-DD] <verb> | <summary>` for easy grepping/tailing.

## [2026-06-03] bootstrap | Created wiki/ structure + schema + initial index + first raw sources (project docs + scripts + pr-14 + nixos-gaming-setup)
- Ran mkdir wiki/{raw,wiki}
- Symlinked all main md files + scripts + metadata from repo into wiki/raw/
- Wrote raw/pr-14-nixos-discussion.md (extracted key comments, workarounds, open questions from GitHub PR)
- Wrote raw/nixos-gaming-setup.md (lutris module forcing umu, gaming group packages including xxd, steam proton-ge, fetch7zip custom pkg, AI skill wiring)
- Wrote wiki/WIKI.md (tailored schema with NixOS focus, ingest workflow, page types, maintenance)
- Wrote wiki/index.md (sections for entities, methods, platforms, concepts; listed initial sources)
- Wrote this log entry
- Status: Ready for first content ingest and NixOS analysis pass. Todo list active for full support work.

## [2026-06-03] ingest | PR #14 + nixos gaming setup (synthesized into platforms and concepts)
- Created wiki/wiki/nixos-support.md (comprehensive page pulling PR discussion, FHS explanation, exact sessionVariables + package advice, script assumptions, user's dotfiles patterns, testing notes on this host).
- Created wiki/wiki/spt-additions-script.md (architecture, CLI, critical functions for cross-platform (m_umu, check_native_deps, check_aspnet), NixOS pain points called out with links).
- Created wiki/wiki/dotnet-for-server.md (why the Linux server binary needs host aspnet + DOTNET_ROOT, contrast to windows runtimes installed in prefix, check_aspnet behavior).
- Created wiki/wiki/dep-management.md (the check/install_dep flow, why it interacts badly with "provide via nix" preference on NixOS).
- Updated index.md (already had forward links; pages now exist).
- Appended this log entry.
- Cross-refs added between pages. Raw sources already linked.

## [2026-06-03] changes | Landed initial NixOS support improvements (docs + script + wiki)
- Updated docs/aspnet.md: Added comprehensive Nixpkgs section with package attrs, critical DOTNET_ROOT sessionVariables example + verification, link to wiki and PR#14.
- Updated README.md: Replaced hard "not supported" WARNING with informative NOTE under Additions CLI, pointing to aspnet Nix section + in-repo wiki/nixos-support + PR.
- Enhanced scripts/spt-additions:
  - Added UMU_CMD var (default UMU_PATH).
  - m_umu now prefers UMU_CMD (allows wrapper).
  - In main(): on /etc/NIXOS + steam-run present, set UMU_CMD="steam-run ..." and print guidance msg (early, visible even with --no-ansi).
  - Updated direct BSG launcher umu call + example msg to use the wrapped cmd.
  - In check_aspnet(): if NixOS, emit specific advice about dotnet-aspnetcore_9 + DOTNET_ROOT (links to docs/wiki).
  - In check_native_deps(): always emit NixOS note at start of check (prefer nix-provided tools; reference wiki pages). Previously after loop.
- All changes syntax-checked (bash -n). Live-tested on this NixOS 26.05 host (via nix-shell for python/curl): wrapper msg + dep Nix note printed; UMU_CMD set when steam-run present.
- Minor: created a couple supporting wiki pages during ingest (dotnet-for-server, dep-management).
- See wiki/wiki/nixos-support.md for the full plan/status and remaining work (Lutris tips, more direct call sites, .desktop shortcuts, testing matrix, long-term nix pkg thoughts).

## [2026-06-03] lint | Wiki health after session
- index.md and log.md updated with new/changed pages.
- Cross-refs added (nixos-support <-> script <-> dotnet <-> dep <-> raw pr & dotfiles).
- Schema (WIKI.md) already covers NixOS priority.
- Orphan/stale: a few planned pages (fhs-and-containers, install-modes, patching-flow) are still forward-refs in index; will flesh on next use or query. No contradictions introduced.
- Raw sources + wiki/ are git-tracked; commit the wiki/ dir + docs/README/script changes together.

## [2026-06-03] lint + ingest | Post-implementation wiki maintenance per llm-wiki skill (from user's dotfiles/modules/ai/skills/llm-wiki)
- Performed lint: Compared actual `wiki/wiki/*.md` files vs. links in index.md and schema.
  - Orphans / incomplete: Many planned pages still only in index (native-umu-install, various lutris-*, install-modes, patching-flow, shortcuts-and-env, etc.). Left as "Planned / Stub Pages" section with note to create on demand.
  - Created lightweight but useful pages for high-value missing ones: launch-server-script.md (using raw symlink + NixOS notes), metadata-conf.md, fhs-and-containers.md (core to understanding the umu wrapper we just added).
  - Fixed duplicate in index (dotnet-for-server listed twice).
  - Updated nixos-support.md and spt-additions-script.md with "changes landed" / "implemented mitigations" sections.
  - Added cross-refs to the new raw/session-2026-06-03-nixos-implementation.md everywhere relevant.
- New ingest: Added raw/session-2026-06-03-nixos-implementation.md (full session summary, rationale for each edit, how the wiki drove precise changes, remaining items).
- Updated Sources Ingested + Last updated in index.md.
- Schema (WIKI.md) remains the governing document; all operations followed its "Ingest", "index.md + log.md", and "Lint" sections.
- Result: Wiki is now a tighter, more current reflection of both the project sources *and* the work we just shipped for NixOS support.

*(Log will grow with every source added and every significant synthesis/query.)*
