# PR #14: NixOS Additions/Changes (WIP) - Key Discussion Excerpts

**Source**: https://github.com/MadByteDE/SPT-Linux-Guide/pull/14 (fetched 2026)
**Author**: CanvasofSpores (WIP draft)
**Status**: Stalled; PR author moved back to Arch; some user reports of partial success. Labeled enhancement + help wanted.
**Main branch impact**: Warning added to README that NixOS is not supported, linking this PR. Some commits on history (e.g. 9057d90 added Nix section to aspnet docs; later warning commits).

## Core Problem Summary (from thread)
NixOS is not FHS-compliant. Most apps live in /nix/store with declared deps. Tools like umu-launcher (pressure-vessel, Steam runtime container) expect traditional FHS paths (/lib, /usr/lib etc.) for dynamic libraries. This breaks the native `spt-additions` install path (UMU + GE-Proton).

Lutris-based install (additions script via Lutris) had more success reports.

## Specific User Reports & Workarounds

### From matt-harp (successful on NixOS, using Lutris additions?):
- Set in configuration.nix (or home-manager equiv):
  ```nix
  environment.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-aspnetcore_9}/share/dotnet/";
  };
  ```
  Without this: "You must install .NET to run this application." when running the (Linux) server.
- In Lutris SPTarkov - Launcher config:
  - Disable System options > Pre-launch script (the launch-server.sh caused issues).
- For server: Add a *native* (non-Wine) game entry in Lutris pointing to `SPTarkov/SPT/SPT.Server.Linux` (CLI mode) or to `SPTarkov/launch-server.sh` (to use local terminal emulator).
  - "Trying to run it using the launch script under wine wouldn't work on my setup, plus splitting them into server and client is preferable for me anyway."

### PR author (CanvasofSpores) responses:
- Acknowledged magnitude of "NixOS is not FHS compliant".
- "Personally, my way of solving this was by using steam-run which uses steam's FHS environment."
- "The 'proper' way to handle this would be to properly package up the program as a nix package, I'd imagine. That's just a *lot*."
- Later: "Gotcha, so this was using the lutris-additions script? any chance you could try using the new install script that doesn't use lutris?"

### Other comments:
- One user: "I managed to get it work with just environment.sessionVariables.DOTNET_ROOT = \"${pkgs.dotnet-aspnetcore_9}/share/dotnet/\"; And installing the correct dependencies for it ofc. The script ran fine and everything installed correctly except the spt-additions cli."
- Issues with dynamically linked executables under umu/pressure-vessel.
- Suggestion: "You can just put everything in fhs env".
- Link to related nixpkgs issue: NixOS/nixpkgs#285642 (about dynamic linking?).

## Changes in the PR (from history)
- 9057d90: Added Nix/NixOS section to docs/aspnet.md recommending `dotnet-aspnetcore_9` in systemPackages or home.packages. Notes package name may change; link to search.nixos.org.
- Later commits on main added the "NixOS is currently not supported" warning in README (with link to this PR).
- Some discussion of merging if confirmed working with the DOTNET_ROOT + other tweaks.

## Open Questions from Thread
- Does the pure `spt-additions` (no-Lutris) path work end-to-end with steam-run wrapper + DOTNET_ROOT?
- What exact native packages/deps are required on NixOS (beyond umu, 7z, jq, etc.)?
- How to handle self-update / script installation ("spt-additions cli")?
- Should the guide/script auto-detect NixOS (/etc/NIXOS) and adjust behavior / messaging (e.g. recommend steam-run, set hints for umu)?
- Full nix derivation for SPT would be ideal long-term but high effort.

## Related Context (2026)
Current README still carries the warning. No NixOS section in aspnet.md on main. User's dotfiles (see raw/nixos-gaming-notes.md) provide umu-launcher, proton-ge-bin, lutris integration with forced nixpkgs umu, xxd, etc. via home-manager.

This wiki entry serves as the synthesized source for planning proper NixOS support work.
