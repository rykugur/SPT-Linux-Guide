
<img
  src="media/logo.webp"
  alt="drawing"
  style=" display: block; 
          margin-right: auto;" width=450/></img>

Here you can find everything you need to install & play SPT on Linux.

## Bug reports

> [!IMPORTANT]
> This guide has been written by the SPT community and is **NOT** officially supported by the SPT developers.

If you encounter an issue while playing SPT on Linux, do **NOT** report it to the dev's unless you're 100% sure it affects Windows installations as well. If possible, verify the issue on a Windows installation of the mod before reporting it.

## Overview

### Automated install

Additions CLI installer
  - 

  > [!NOTE]
  > **NixOS users**: The script can work but requires extra setup (mainly `dotnet-aspnetcore_9` + `DOTNET_ROOT` session variable, and often `steam-run` to wrap umu-run for FHS reasons). See the [Nixpkgs section in aspnet docs](docs/aspnet.md) and the detailed [[wiki/wiki/nixos-support.md]] (or the file `wiki/wiki/nixos-support.md` after cloning the repo) + historical PR [#14](https://github.com/MadByteDE/SPT-Linux-Guide/pull/14). Lutris additions path has more success reports. Help testing/improving is welcome!

  - Guided installer for EFT/SPT using UMU-Launcher / GE-Proton directly (without Lutris/Bottles)
  - ⚠️ Uses a custom **native Linux** bash script ([view source](scripts/spt-additions))

  1. Install the `aspnetcore-runtime-9.0` system package ([how to install](docs/aspnet.md))
  3. Run the following command in a terminal:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/MadByteDE/SPT-Linux-Guide/main/scripts/spt-additions)"
```

[Lutris installer](docs/lutris/installer_additions.md) (Additions)
  - 
  - ⚠️ Uses a custom **native Linux** bash script ([view source](scripts/spt-additions))


### Others

#### [Lutris installer](docs/lutris/installer_official.md) (Official)

  - Uses the official [SPTInstaller](https://github.com/sp-tarkov/installer) via `Wine`
  - ⚠️ Uses a custom server pre-launch script ([view source](scripts/launch-server.sh))


#### Manual install (Unsupported)
- [Using Lutris](docs/lutris/manual_guide.md)
- [Using Bottles](docs/bottles/manual_guide.md)

### [FAQ](docs/faq.md)

### [Troubleshooting](docs/issues.md)

## Development

This repository includes a Nix flake + devenv-based development shell aimed at making it easy to develop and debug the `spt-additions` installer script (especially the NixOS-specific paths).

### Quick start (with direnv)

```bash
direnv allow
```

### Without direnv

```bash
nix develop
# or
devenv shell
```

The shell provides the exact tools the script looks for (`umu-run`, `7zzs`, `hpatchz`, `jq`, `xxd`, `steam-run`, ASP.NET runtime, etc.) plus development helpers like `shellcheck` and `just`.

See the `justfile` for common tasks:

```bash
just --list
just check
just version
just run-steam --no-ansi --no-prompt version   # explicitly test the steam-run wrapper path
```

The script should now auto-detect NixOS (`/etc/NIXOS`) + `steam-run` and wrap `umu-run` automatically. The dev shell makes this easy to iterate on.

### Why a dev shell?

- Reproducible environment for the script's native dependencies on NixOS (and other distros).
- Easy testing of the FHS/umu wrapper logic without polluting your user profile.
- Shellcheck + syntax checks during development.

## Contributions
If you want to contribute to the guide, feel free to:
- Send us a [pull request](https://github.com/MadByteDE/SPT-Linux-Guide/compare/SPTv4-Dev...main)
- Open a [new issue](https://github.com/MadByteDE/SPT-Linux-Guide/issues/new/choose)
- Contact us on [Discord](https://discord.com/invite/Xn9msqQZan)

If you want to send us a PR, please make sure the formatting of your addition matches the existing content in our guide.


## Find us on Discord
Check out the offical [SPT Discord server](https://discord.com/invite/Xn9msqQZan)!


## Credits

Thanks to everyone helping out and contributing to the guide <3 !

### Guide contributors:
- **APoorDev**
- **dj3hac**
- **Laserpulse**
- **LinuxFromMars**
- **nyuware**
- **Penkov**
- **TheSpectator**
- **Witek**

