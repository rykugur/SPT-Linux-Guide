# User's NixOS Gaming Setup (Relevant to SPT / Wine / UMU)

**Source**: User's personal dotfiles repository (declarative NixOS + home-manager config, flake-based). Extracted during 2026 session for SPT-Linux-Guide wiki.

## Gaming Group (modules/groups/gaming.nix)
Provides common gaming packages for home-manager:
- Imports: discord, lutris (homeManager modules)
- Packages: steamcmd, protonplus, protonup-ng, protonup-qt, winetricks, bottles, dxvk, gamescope, heroic, mangohud, moonlight-qt, unixtools.xxd, vkd3d, xdelta

## Lutris Module (modules/gaming/lutris.nix)
```nix
{ pkgs, osConfig, ... }:
{
  home.packages = with pkgs; [ umu-launcher ];

  programs.lutris = {
    enable = true;
    extraPackages = with pkgs; [
      mangohud winetricks gamescope gamemode umu-launcher wmctrl
    ];
    steamPackage = osConfig.programs.steam.package;
    protonPackages = [ pkgs.proton-ge-bin ];
    winePackages = [ pkgs.wineWow64Packages.stagingFull ];
  };

  # force lutris to use nixpkgs umu-launcher (overrides any bundled)
  home.file = {
    ".local/share/lutris/runtime/umu/umu-run" = {
      source = "${pkgs.umu-launcher}/bin/umu-run";
      force = true;
    };
  };
}
```

Key: Explicitly installs and forces umu-launcher from nixpkgs into Lutris runtime dir. This is important because the SPT additions Lutris installer and native script rely on `umu-run`.

## Steam Module (modules/gaming/steam.nix)
NixOS-level:
```nix
programs.steam = {
  enable = true;
  remotePlay.openFirewall = true;
  dedicatedServer.openFirewall = true;
  extraPackages = with pkgs; [ gamemode ];
  extraCompatPackages = [ pkgs.proton-ge-bin ];
  protontricks.enable = true;
};
```

## Other Relevant
- pkgs/fetch7zip.nix : Custom fetcher using p7zip to extract 7z archives during nix builds. Shows awareness of 7z tooling. (Script uses 7zzs binary from 7zip release.)
- In gaming.nix and hosts, unixtools.xxd is provided (script requires `xxd` for hashing).
- Example hosts: Use linuxPackages_zen, chaotic mesa-git (temporary workaround), amdgpu, etc. No SPT-specific in base config, but full gaming group imported on relevant hosts.
- AI skills: llm-wiki skill is provided to opencode/codex/claude-code/pi agents via the modules (src = ./skills/llm-wiki).

## Implications for spt-additions
- User is expected to have `umu-run` in PATH via the lutris/gaming modules or direct `pkgs.umu-launcher`.
- `jq`, `xxd` typically available.
- `7zzs`: May come from `p7zip` (provides `7z`) or need the standalone 7zip pkg; script downloads its own if missing.
- For native .NET server: User will need to add `dotnet-aspnetcore_9` (or current equiv like `dotnetCorePackages.aspnetcore_9_0`) + set `DOTNET_ROOT` in sessionVariables (as discussed in PR #14).
- FHS issues for umu/pressure-vessel are mitigated in user's setup by using nixpkgs versions + Steam's proton-ge + potentially `steam-run` for ad-hoc FHS when running non-nix-wrapped binaries (as mentioned in PR thread by author).
- Lutris is configured with proton-ge-bin and staging wine.

This setup provides a strong base; the guide/script just needs to document the extra sessionVariables + any wrapper advice for pure native installs, and perhaps detect NixOS to give tailored advice.
