# SPT Linux Guide Wiki - Schema & Conventions

This wiki is an LLM-maintained, persistent, interlinked knowledge base for the SPT-Linux-Guide project (https://github.com/MadByteDE/SPT-Linux-Guide).

It sits between raw sources (the guide docs, installer script, external discussions like PRs, user's Nix configs) and any queries or synthesis work (e.g. making the installer work on NixOS).

**Goal**: Accumulate understanding so that future work (bugfixes, NixOS support, script changes, docs) builds on synthesized knowledge instead of re-reading everything every time. Cross-references, entity pages, platform notes, and architecture overviews live here.

## Directory Layout
- `raw/`: Immutable source material. Symlinks to project files or dedicated .md files capturing external content (PR discussions, config excerpts). Never edit originals through the wiki layer. Add new sources here when ingesting.
- `wiki/`: The living wiki. All LLM-generated/updated pages live here. Markdown only (for now). Use Obsidian or any md viewer for graph/links.
- `WIKI.md` (this file): The schema. Read it on every session. Update it when conventions evolve.
- `index.md`: Content-oriented catalog. One-line summaries + links for every important page. Organized by sections (e.g. ## Core Entities, ## Platform Support, ## Script Architecture). LLM updates on every ingest.
- `log.md`: Chronological append-only history. Entries start with `## [YYYY-MM-DD] <action> | <title>`. Use for timeline and quick recent context.

## Page Types & Naming
- **Entity pages**: Things that exist (e.g. `spt-additions-script.md`, `umu-on-nixos.md`, `dotnet-aspnet-server.md`, `lutris-installer-flow.md`).
- **Concept pages**: Ideas/architecture (e.g. `install-modes.md`, `fhs-issues.md`, `dep-management.md`).
- **Platform pages**: `nixos-support.md`, `arch-support.md` etc. One per major distro/family with gotchas + exact config snippets.
- **Synthesis pages**: Answers to big questions, PR retros, "how to add X support", release notes analysis. These can be filed from chat.
- **Source summaries**: For large/complex raw sources, a `wiki/summary-<source>.md` that extracts key facts, with links back to raw.
- Naming: kebab-case, descriptive, no dates unless historical. Use folders under wiki/ only if it grows large (e.g. wiki/platforms/).

## Ingest Workflow (for LLM)
1. Read the new raw source(s) fully (use tools: read_file, open_page, rg, terminal).
2. Discuss key takeaways with user if non-obvious.
3. Create or update 5-15 relevant wiki pages:
   - New summary or entity page for the source.
   - Update entity pages (e.g. add "NixOS notes" section to script page).
   - Update platform pages.
   - Strengthen cross-links (use [[wikilink]] or relative md links).
   - Note contradictions with prior knowledge (e.g. "PR#14 claimed X but current script at vY does Z").
4. Update `wiki/index.md`: Add entry under appropriate section with 1-line summary + link + source count or date.
5. Append to `log.md` with consistent prefix.
6. Optionally update this WIKI.md if new pattern observed.

Prefer incremental: one source at a time, keep user in loop for emphasis.

When ingesting code (script): Focus on public interface (CLI options, env vars, functions like m_umu, install_spt_native, check_native_deps), hardcoded assumptions (paths, commands), and platform-specific branches (lutris mode etc.). Do not dump the whole 2200 lines.

## Query / Synthesis Workflow
- Always start by reading `wiki/index.md` to locate relevant pages.
- Read the pages, follow links.
- Synthesize answer.
- If the answer is valuable and non-ephemeral (a decision, a plan, a comparison, a troubleshooting tree), write it as a new wiki page (or update existing) and link from index/log.
- Cite sources (raw files + wiki pages).

## NixOS Focus (current priority work)
Track:
- Exact package names/attributes that work on current nixpkgs (test on host: 26.05+).
- Required `environment.sessionVariables` or `home.sessionVariables`.
- How to invoke `umu-run` successfully (plain, `steam-run $(which umu-run)`, wrappers in script?).
- Deps the script can auto-provide vs. ones that must come from nix (to avoid double-download or FHS conflicts).
- Lutris vs. pure native path differences on NixOS.
- Server launch (native binary + DOTNET_ROOT).
- Self-install / PATH / `spt-additions` command availability.
- Long-term: feasibility notes toward a nix package vs. guide-only support.

Update `wiki/platforms/nixos.md` (create when first ingesting) as the canonical page. Link it from README synthesis later.

## Maintenance / Lint
Periodically (or on request):
- Scan index for orphan pages (no inbound links).
- Check for stale claims (e.g. "NixOS unsupported" after we land support).
- Look for missing cross-refs between script behaviors and platform notes.
- Propose new questions/sources to user.
- Keep log tidy; use it to replay recent evolution.

## Tooling Notes
- This is plain git-tracked markdown. `git add wiki/ && git commit` after significant updates.
- For search: later can add qmd or simple rg scripts if scale demands.
- Images: if any screenshots of installs on Nix, put in wiki/assets/ and reference.
- Since this wiki lives inside the SPT-Linux-Guide repo, it can be referenced in future PRs or as advanced docs.

## Evolution
This schema co-evolves. When a new pattern helps (e.g. "decision records" subdir, or frontmatter for dataview), document it here and adjust existing pages in the same pass.

*Initialized + maintained following the llm-wiki skill at modules/ai/skills/llm-wiki/SKILL.md in the user's dotfiles (the authoritative pattern in this setup).*

*Initialized during "We're doing WORK today" session focused on llm-wiki + PR#14 NixOS support. Continued with lint + session ingest after landing the first round of script/docs changes.*
