
## ASP.NET Runtime 9.0

[Website](https://dotnet.microsoft.com/en-us/download/dotnet/9.0)

To run the native Linux server you need to install the native ASP.NET Runtime 9 system package.

## How to install

### Ubuntu / Debian

> [!NOTE]
> On Debian you might need to add the Microsoft package repository first:
```
curl https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb -o packages-microsoft-prod.deb
```
```
sudo dpkg -i packages-microsoft-prod.deb
```
```
rm packages-microsoft-prod.deb
```

> [!NOTE]
> On Ubuntu-based distributions you might need to add the `dotnet/backports` PPA:

```
sudo add-apt-repository ppa:dotnet/backports
sudo apt update
```

Now you can install the package:
```
sudo apt-get update && \
sudo apt-get install -y aspnetcore-runtime-9.0
```

### Fedora (based)
```
sudo dnf install aspnetcore-runtime-9.0
```

### Fedora Atomic (e.g. Bazzite/Aurora/Bluefin)
```
rpm-ostree install aspnetcore-runtime-9.0
```

### Arch (based)
```
sudo pacman -S aspnet-runtime-9.0
```

### Nixpkgs (NixOS or any Nix-based system)
> [!IMPORTANT]
> The Linux SPT server (`SPT/SPT.Server.Linux`) is a native .NET 9 application. On NixOS it will fail with "You must install .NET to run this application" (or similar) unless both the package *and* `DOTNET_ROOT` are configured.

Add the package (system-wide or per-user):
```nix
# configuration.nix (system)
environment.systemPackages = with pkgs; [
  dotnet-aspnetcore_9   # or dotnetCorePackages.aspnetcore_9_0
];
```

```nix
# home.nix / home-manager (user only)
home.packages = with pkgs; [
  dotnet-aspnetcore_9
];
```

**Critical**: Also set the session variable so the runtime is discoverable:
```nix
environment.sessionVariables = {
  DOTNET_ROOT = "${pkgs.dotnet-aspnetcore_9}/share/dotnet/";
};
```
(or `home.sessionVariables` for home-manager). Log out/in or `exec $SHELL` after `nixos-rebuild switch`.

**Verification** (after rebuild + new shell):
```bash
dotnet --list-runtimes | grep -i aspnet
# Should show something with 9.0
```

The `spt-additions` script will also perform a non-fatal check for AspNet 9.0 before installing SPT. The same `DOTNET_ROOT` lets the installed `SPT.Server.Linux` actually start.

See the [NixOS support wiki page](wiki/wiki/nixos-support.md) (in this repo) and historical PR [#14](https://github.com/MadByteDE/SPT-Linux-Guide/pull/14) for more context, steam-run workarounds for the installer itself, and Lutris-specific tips.

***
Still having issues? Visit our [issues section](../../docs/issues.md).

***

[Back to landing page](../README.md)
