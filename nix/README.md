# nix/

Internal helpers for the **runnable artifacts** exposed by this flake
(spt-additions, spt-server, spt-launcher + dev shell).

As of the recent changes, this repository's flake concerns itself **only**
with these runnable tools. The declarative mod builders and Home Manager
module are no longer part of the published flake outputs (`lib`, `homeModules`,
overlay `sptMods`, etc.).

The files under `nix/` (especially `spt-mods.nix` and `modules/home-manager/spt.nix`)
remain in the source tree as reference material. They can be used as a basis
for implementing similar functionality in a consuming flake that imports this
one.

## Layout

```
nix/
├── default.nix          # Helpers for the tools only (mkCoreScriptDeps, mkSptPackages, etc.)
├── README.md            # This file.
├── spt-mods.nix         # (Reference) Pure data + builders for declarative mods. Not wired into the flake anymore.
├── devshell.nix         # The `nix develop` / direnv shell.
├── packages/
│   ├── spt-server.nix   # Hermetic spt-server (DOTNET_ROOT + desktop file + icon + signal handling).
│   ├── spt-additions.nix# The main installer, wrapped with all its runtime deps (also pulls in spt-server).
│   └── spt-launcher.nix # Thin wrapper: `spt-additions run launcher`.
└── modules/
    └── home-manager/
        └── spt.nix      # (Reference) Old HM module. Not exported from the flake.
```

## default.nix

`import ./nix { inherit lib; }` now gives you only the tool-related helpers:

- `mkCoreScriptDeps pkgs`
- `packageDefs`
- `mkSptPackages pkgs lib` → the three runnables + `default`
- `devshell`

This keeps the perSystem wiring in `flake.nix` tiny and focused on runnables.

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

## Mods and Home Manager module (now reference material only)

The files `spt-mods.nix` and `modules/home-manager/spt.nix` are **no longer exported** via the flake (`lib`, `homeModules`, `overlays.*.sptMods`, etc.).

They are kept in the tree because the mod installation pattern (extract archive → merge BepInEx/ + SPT/ trees into a mutable `~/Games/SPTarkov`) and the activation-time rsync approach are still useful.

If implementing declarative mods + an HM module, the logic can be copied/adapted from these files into a consuming flake while importing *this* flake to get the underlying `spt-server` / `spt-additions` packages.

See the files themselves for the previous implementation details (version map, passthru.dependencies, resolveModClosure, rsync --ignore-existing, etc.).

## Using this as a flake input

```nix
# your flake
inputs.spt-linux-guide.url = "github:MadByteDE/SPT-Linux-Guide";

# then (only the runnables)
nixpkgs.overlays = [ inputs.spt-linux-guide.overlays.default ];

environment.systemPackages = [
  pkgs.spt-additions
  pkgs.spt-server
  pkgs.spt-launcher
];
```

You can still call `mkSptPackages` / `mkCoreScriptDeps` / import the raw `packageDefs` directly if you want to build custom wrappers.

(The old `lib.mkSptMods`, `homeModules.spt`, and `pkgs.sptMods` are no longer provided by this flake.)

## Development / testing

- `nix flake check`
- `nix build .#spt-server .#spt-additions .#spt-launcher`
- `nix run .#spt-server`
- `nix develop` (or direnv) gives you the full script environment + linters.
- `just` targets (see root justfile) for common tasks.

When working on the mod-related reference files (`spt-mods.nix` etc.), you can still build them directly with `--expr` for testing:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --expr '
  let
    f = builtins.getFlake (toString ./.);
    pkgs = import <nixpkgs> { system = "x86_64-linux"; config.allowUnfree = true; };
  in (import ./nix/spt-mods.nix { lib = pkgs.lib; }).mkSptMods pkgs "4.0.13" .sain
'
```

## Notes / gotchas

- This flake deliberately does **not** try to package the entire SPTarkov tree. The proprietary + user-writable parts stay in `~/Games/SPTarkov`. We only package the *runnable tools*.
- The mod reference files still follow the same "extract to BepInEx/ + SPT/ then merge" model that the bash installer uses.

Happy hacking on the launchers and installer script! The mod + module bits are out of scope for this flake.
