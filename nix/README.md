# nix/

Internal helpers for the **runnable artifacts** exposed by this flake
(spt-additions, spt-server, spt-launcher + dev shell).

This repository's flake focuses **only** on these runnable tools for installing
and running SPT on Linux (with good NixOS support).

## Layout

```
nix/
├── default.nix    # Helpers for the tools (mkCoreScriptDeps, mkSptPackages, etc.)
├── README.md      # This file.
├── devshell.nix   # The `nix develop` / direnv shell.
└── packages/
    ├── spt-server.nix     # Hermetic spt-server (DOTNET_ROOT + desktop file + icon + signal handling).
    ├── spt-additions.nix  # The main installer, wrapped with all its runtime deps (also pulls in spt-server).
    └── spt-launcher.nix   # Thin wrapper: `spt-additions run launcher`.
```

## default.nix

`import ./nix { inherit lib; }` gives you:

- `mkCoreScriptDeps pkgs` — the list of native tools needed by the scripts.
- `packageDefs` — paths to the individual package expressions.
- `mkSptPackages pkgs lib` — returns `{ spt-additions, spt-server, spt-launcher, default = spt-server; }`.
- `devshell` — path to the devshell expression.

This keeps the perSystem wiring in `flake.nix` tiny and focused on the runnables.

## Packages (the focus of this flake)

Each `packages/*.nix` returns a derivation (usually via `writeShellApplication` or `symlinkJoin` for the desktop bits).

- They are hermetic: `runtimeInputs` + explicit `DOTNET_ROOT` etc.
- `spt-additions.nix` deliberately does a relative `import ./spt-server.nix` so that `spt-additions run server` can exec the dedicated launcher (and gets it in the closure).
- Desktop icon + .desktop for `spt-server` live under the media tree; the path is passed explicitly from `mkSptPackages` (and has a `../../media` default inside the package file that works because of the layout under `nix/`).

To add a new first-class runnable tool:

1. Add `nix/packages/my-tool.nix`.
2. Add it to `packageDefs` and `mkSptPackages` in `default.nix`.
3. (Optional) expose under `apps` in the flake.
4. Add to devshell if needed for hacking.
5. Update docs.

## Using this as a flake input

```nix
inputs.spt-linux-guide.url = "github:MadByteDE/SPT-Linux-Guide";

# then
nixpkgs.overlays = [ inputs.spt-linux-guide.overlays.default ];

environment.systemPackages = [
  pkgs.spt-additions
  pkgs.spt-server
  pkgs.spt-launcher
];
```

You can also call `mkSptPackages` / `mkCoreScriptDeps` / import the raw `packageDefs` directly if you want to build custom wrappers.

## Development / testing

- `nix flake check`
- `nix build .#spt-server .#spt-additions .#spt-launcher`
- `nix run .#spt-server`
- `nix develop` (or direnv) gives you the full script environment + linters.
- `just` targets (see root justfile) for common tasks.

## Notes / gotchas

- This flake deliberately does **not** try to package the entire SPTarkov tree. The proprietary + user-writable parts stay in `~/Games/SPTarkov`. We only package the *runnable tools*.

Happy hacking on the launchers and installer script!
