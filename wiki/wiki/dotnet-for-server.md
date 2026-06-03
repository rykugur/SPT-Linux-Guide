# .NET / ASP.NET for SPT Server

The SPT server for 4.x (`SPT/SPT.Server.Linux`) is a native Linux binary built against .NET 9 (C# rewrite of previous Aki server).

On traditional distros: install `aspnetcore-runtime-9.0` system package (apt, pacman, dnf, rpm-ostree). The `dotnet` command becomes available and the runtime is in standard locations.

On NixOS: the runtime lives in the nix store. Two things are required:
1. The package in `environment.systemPackages` or `home.packages` so the files exist: `dotnet-aspnetcore_9` (or `dotnetCorePackages.aspnetcore_9_0`).
2. `DOTNET_ROOT` environment variable pointing at the `share/dotnet` inside that package so the server binary (and any `dotnet` commands) can locate the runtime, BCL, etc.

Example (see [[nixos-support]] for full context and package name evolution):
```nix
environment.sessionVariables.DOTNET_ROOT = "${pkgs.dotnet-aspnetcore_9}/share/dotnet/";
```

The script's `check_aspnet()` does a non-fatal check:
```bash
if ! dotnet --list-runtimes 2>/dev/null | grep "AspNet" | grep "9.0" &>/dev/null; then
    warn "..."
fi
```
This can succeed once the var + package are set (or `dotnet` from the aspnet package is on PATH).

During `install spt` the script also installs *Windows* .NET Desktop Runtimes (6/8/9) *inside the Wine prefix* using `m_umu` + the downloaded exe. Those are for the game/launcher (BepInEx, SPT core, etc.), not the host Linux server.

**Fika server mod** also runs on the Linux server and thus inherits the same host .NET requirement.

## Cross References
- [[nixos-support]]
- [[spt-additions-script]] (check_aspnet, install_spt_native)
- Raw aspnet doc: [[raw/aspnet.md]]
- PR #14 discussion: [[raw/pr-14-nixos-discussion.md]]

When package names shift in nixpkgs, update the aspnet.md guide section and this page.
