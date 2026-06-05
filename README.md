
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

This repository includes a Nix flake (structured with [flake-parts](https://github.com/hercules-ci/flake-parts)) aimed at making it easy to develop the `spt-additions` installer, run SPT-related tools, and — most importantly — consume the guide from other flakes (your desktop config, deploy scripts, etc.).

The long-term intent is that you can add this repo as a flake input and get:

- A reliable way to run `spt-additions` (the installer) with all its native dependencies on any Nix machine.
- `spt-server`, `spt-launcher`, and other launchers.
- (Planned) NixOS / home-manager modules for declarative setup of the server, desktop entries, DOTNET_ROOT, etc.

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

The dev shell provides the exact tools the `spt-additions` script expects (`umu-run`, `7zzs`, `steam-run`, `jq`, `xxd`, ASP.NET runtime, etc.) plus helpers like `shellcheck`, `shfmt`, and `just`.

See the `justfile` for common tasks:

```bash
just --list
just check
just version
just run-steam --no-ansi --no-prompt version   # explicitly test the steam-run wrapper path
just server          # direct (inside dev shell)
just spt-server      # via the packaged launcher
```

The script auto-detects NixOS (`/etc/NIXOS`) + `steam-run` and wraps `umu-run` automatically. The dev shell makes iteration easy.

### Packaged runnable entrypoints (the scope of this flake)

This flake now focuses **only** on the three runnable tools:

- `spt-additions` — the main installer (umu + Proton path)
- `spt-server` — dedicated launcher for the native Linux SPT server
- `spt-launcher` — convenience wrapper to launch the SPT client/launcher GUI

Everything else (Home Manager module, declarative mod builders + version map, `lib.mkSpt*`, `pkgs.sptMods`, etc.) has been removed from the public flake API. You maintain those in your personal configuration flake (e.g. `~/.dotfiles`), importing this repo only to obtain the underlying tools.

#### `spt-additions` — the installer

```bash
# Run the additions installer directly (all native deps provided by the flake)
nix run github:MadByteDE/SPT-Linux-Guide#spt-additions

# Or from a pinned input in your own flake:
# packages = [ inputs.spt-linux-guide.packages.${pkgs.system}.spt-additions ];
# Then just run `spt-additions`
```

This wrapper ensures that `umu-launcher`, `steam-run`, `7zzs`, `jq`, `xxd`, the ASP.NET runtime, etc. are in `$PATH`, plus `DOTNET_ROOT` is set. Perfect for NixOS or any Nix machine.

You can still use the old one-liner for the absolute latest version, but pinning via the flake gives reproducibility.

#### `spt-server` launcher (for NixOS / end users)

```bash
# Try immediately
nix run github:MadByteDE/SPT-Linux-Guide#spt-server

# Or install persistently
# packages = [ inputs.spt-linux-guide.packages.${pkgs.system}.spt-server ];
```

This gives you a `spt-server` binary that:

- Hardcodes the correct `DOTNET_ROOT` so the native `SPT.Server.Linux` works on NixOS without (or in addition to) global session variables.
- Auto-discovers your SPT install via the guide's config / `SPTARKOV_PATH` / default.
- Ships a `.desktop` file + icon, so "SPT Server" appears in application menus. Uses `Terminal=true`.

See the [[nixos-support]] wiki page for background on the launcher-only packaging approach.

#### `spt-launcher` — the client/launcher GUI

```bash
# Launch the SPT client/launcher (the thing you use to start the actual game)
nix run github:MadByteDE/SPT-Linux-Guide#spt-launcher

# Or from a pinned input:
# packages = [ inputs.spt-linux-guide.packages.${pkgs.system}.spt-launcher ];
# Then just run `spt-launcher`
```

This is a thin convenience wrapper around `spt-additions run launcher`. It gets the full umu + Proton environment (with the NixOS steam-run FHS workaround when needed) so the Windows `SPT.Launcher.exe` runs correctly.

Requires that SPT has already been installed (via `spt-additions` or the Lutris path).

#### Using the tools from your personal flake

```nix
inputs.spt-linux-guide.url = "github:MadByteDE/SPT-Linux-Guide";

# ...
nixpkgs.overlays = [ inputs.spt-linux-guide.overlays.default ];

environment.systemPackages = [
  pkgs.spt-additions
  pkgs.spt-server
  pkgs.spt-launcher
];
```

You can (and are expected to) implement your own Home Manager module + mod builders in your personal config, importing the packages from this input as needed.

### Why a dev shell + flake-parts?

- Reproducible environment for the script's native dependencies (especially the NixOS FHS/umu story).
- Easy testing of installer changes without polluting your user profile.
- `flake-parts` structure makes it clean to consume the *runnables* as an input (`nix run ...#spt-additions`, `packages = [ ... .spt-server ]`, overlays, etc.).
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

