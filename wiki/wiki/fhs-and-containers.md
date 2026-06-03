# FHS and Container Issues (umu / pressure-vessel)

**Why NixOS (and other non-FHS systems) have trouble with the native installer path.**

**Related**: [[nixos-support]], [[spt-additions-script]] (m_umu, UMU_PATH), PR #14 discussion in raw/.

## The Problem
- `umu-launcher` (and its dependency pressure-vessel) is designed around the Steam runtime and expects a traditional Filesystem Hierarchy Standard (FHS) layout: `/lib`, `/usr/lib`, dynamic linker at expected paths, etc.
- On NixOS, *everything* is in `/nix/store/<hash>-name/...` with no global FHS tree. Libraries, interpreters, and configs are only visible to processes that explicitly declare their dependencies.
- When umu spins up a container for a Windows exe (or even some native tools), the inner environment can't find what it expects → "BadMatch", missing libs, or silent failures.

## Workarounds Observed
- **steam-run**: Wraps commands in an FHS environment derived from the Steam runtime. `steam-run umu-run ...` or `steam-run ./spt-additions ...`. This is the approach highlighted by the PR author and now partially automated in the script (when `steam-run` is detected on NixOS).
- Lutris (with user's modules): Pre-configures umu from nixpkgs and proton-ge; many users report the Lutris additions path works with fewer tweaks once DOTNET_ROOT is set.
- `nix-ld` or other dynamic linker shims (less common for this use case).
- Full packaging as a Nix derivation (mentioned as "a lot" of work in the PR thread).

## What the Script Does Now (2026-06-03)
See the implementation in `main()` and `m_umu()`. Detection of `/etc/NIXOS` + presence of `steam-run` → sets `UMU_CMD` wrapper. Messages guide the user.

## Long-term
A proper `sptarkov` Nix package would declare all the runtime deps, bundle or reference the EFT/SPT files, and avoid relying on umu containers for the Linux-native parts. For the guide, the current approach (document + light script awareness) is pragmatic.

## Sources
- PR #14 comments (FHS explanation, steam-run recommendation).
- User's dotfiles (lutris module forcing umu, steam extraCompatPackages).
- Script source (where the wrapper was added).
