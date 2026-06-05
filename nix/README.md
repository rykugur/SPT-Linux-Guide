# nix/

Internal structure for the flake (and for direct consumption via `import ./nix`).

The goal is to keep `flake.nix` tiny (just systems + perSystem wiring + the `flake.*` outputs) while everything else lives here as reusable, importable pieces.

## Layout

```
nix/
├── default.nix          # Public entry point (re-exports + helpers). `import ./nix { inherit lib; }`
├── README.md            # This file.
├── spt-mods.nix         # Pure data + builders for declarative mods.
├── devshell.nix         # The `nix develop` / direnv shell.
├── packages/
│   ├── spt-server.nix   # Hermetic spt-server (DOTNET_ROOT + desktop file + icon + signal handling).
│   ├── spt-additions.nix# The main installer, wrapped with all its runtime deps (also pulls in spt-server).
│   └── spt-launcher.nix # Thin wrapper: `spt-additions run launcher`.
└── modules/
    └── home-manager/
        └── spt.nix      # HM module: packages + DOTNET_ROOT + declarative mod merging via rsync.
```

## default.nix (the key to a short flake.nix)

`import ./nix { inherit lib; }` gives you:

- Everything from `spt-mods.nix` at the top level (`supportedSptVersion`, `mkSptMod`, `mkSptMods`, `sptModVersions`).
- `mkCoreScriptDeps pkgs` — the list of native tools (umu, steam-run, 7zzs, dotnet-9, jq, ...). Single source of truth.
- `packageDefs` — attrset of paths to the individual package expressions.
- `mkSptPackages pkgs lib` — returns `{ spt-server, spt-additions, spt-launcher, default = spt-server; }` ready for `perSystem.packages`.
- `devshell` — path to the devshell expression.
- `modules.homeManager` — path to the home-manager module.

This lets flake.nix do the absolute minimum of `let spt = import ./nix ...; ... packages = spt.mkSptPackages ...;`

## Mods (spt-mods.nix)

### Supported SPT version + the version map

```nix
supportedSptVersion = "4.0.13";
sptModVersions = {
  "4.0.13" = {
    uifixes = { version = "..."; url = "..."; hash = "..."; };
    sain    = { version = "..."; url = "..."; hash = "..."; dependencies = [ "bigbrain" "waypoints" ]; ... };
    ...
  };
  # "4.1.0" = { ... };   # future versions live here too
};
```

- Bump `supportedSptVersion` (and add/update the map entry) manually when we decide to track a new SPT release.
- The map lets you ask for the correct mod versions for a given SPT (e.g. `mkSptMods pkgs "4.0.13"`).
- Hashes are SRI (`sha256-...`). Obtain with:
  - `nix store prefetch-file --json <url> | jq -r .hash`
  - or `nix-prefetch-url --unpack <url>` (then convert to SRI if needed).

### mkSptMod / mkSptMods + dependency handling

- `mkSptMod` takes a release archive (zip/7z/tar/tar.gz/... supported via `7zz` or `tar`), unpacks it into `$out` (so the result contains `BepInEx/` and/or `SPT/` trees), and stashes `passthru.dependencies`.
- `mkSptMods pkgs sptVersion` builds the whole attrset for that version and then walks the declared `dependencies = [ "name" ... ]` (string names) to attach real drvs (deps first).
- The resulting packages have `passthru.dependencies = [ <drv> <drv> ... ]`.
- The HM module (and any future "apply" tool) uses a small `resolveModClosure` walker that flattens the transitive set (deduped, deps-first order) so base frameworks are merged before the mods that need them.

Example of a dep chain today: `sain` → `bigbrain`, `waypoints`.

You can also define your own ad-hoc mods anywhere with `mkSptMod` (point at any GitHub release or even a local tarball via `builtins.fetchurl` etc.).

## Packages

Each `packages/*.nix` returns a derivation (usually via `writeShellApplication` or `symlinkJoin` for the desktop bits).

- They are hermetic: `runtimeInputs` + explicit `DOTNET_ROOT` etc.
- `spt-additions.nix` deliberately does a relative `import ./spt-server.nix` so that `spt-additions run server` can exec the dedicated launcher (and gets it in the closure).
- Desktop icon + .desktop for `spt-server` live under the media tree; the path is passed explicitly from `mkSptPackages` (and has a `../../media` default inside the package file that works because of the layout under `nix/`).

To add a new first-class tool:

1. Add `nix/packages/my-tool.nix` (takes `{ pkgs, ... }` or whatever it needs).
2. Add it to `packageDefs` and `mkSptPackages` in `default.nix`.
3. (Optional) expose under `apps` in the flake if you want `nix run .#my-tool`.
4. Add to devshell if developers need it while hacking the guide.
5. Document in the top-level README.

## Home Manager module

See `modules/home-manager/spt.nix`. Key points:

- `programs.spt.enable`, `.server.enable`, `.launcher.enable` pull in the packages (respecting overrides and the overlay).
- `programs.spt.mods = [ sain uifixes ... ];` (or `pkgs.sptMods.sain` after the overlay) — the module resolves the full closure and does a non-destructive `rsync -a --ignore-existing` of the `BepInEx/` and `SPT/` trees into `~/Games/SPTarkov` on activation.
- This preserves the "mutable SPT + user data" model while still giving you declarative, reproducible, version-pinned mods from Nix.
- `DOTNET_ROOT` is also managed (can be disabled).

## Using this as a flake input (the whole point)

```nix
# your flake
inputs.spt-linux-guide.url = "github:MadByteDE/SPT-Linux-Guide";

# then
nixpkgs.overlays = [ inputs.spt-linux-guide.overlays.default ];

# packages
environment.systemPackages = [ pkgs.spt-server ];

# or via home-manager
imports = [ inputs.spt-linux-guide.homeModules.spt ];

programs.spt = {
  enable = true;
  server.enable = true;
  mods = with (inputs.spt-linux-guide.lib.mkSptMods pkgs inputs.spt-linux-guide.lib.supportedSptVersion); [
    sain   # pulls bigbrain + waypoints for you
  ];
};
```

You can also call `mkSptPackages` / `mkCoreScriptDeps` / import the raw package files directly if you want to build your own wrappers.

## Development / testing

- `nix flake check`
- `nix build .#spt-server .#spt-additions .#spt-launcher`
- `nix build .#legacyPackages.x86_64-linux.sptMods.sain` (easy `result` symlink for any mod)
- `nix run .#spt-server`
- `nix develop` (or direnv) gives you the full script environment + linters.
- `just` targets (see root justfile) for common tasks.

### Inspecting mod content (the "how files get into place" part)

The mod packages (built by `mkSptMod` / `mkSptMods`) are just derivations whose `$out` contains the `BepInEx/` and/or `SPT/` trees extracted from the release. These are what the HM module (or you manually) rsync into your live `~/Games/SPTarkov`.

To get an easy-to-find `result` symlink **without** memorizing long `/nix/store/...` hashes:

```bash
# Build one (or more) and get ./result (or result-1, ...)
# (We use legacyPackages because flake-parts expects `packages.*` entries
# to be single derivations, not attrsets.)
nix build .#legacyPackages.x86_64-linux.sptMods.sain .#legacyPackages.x86_64-linux.sptMods.uifixes

ls -l result
realpath result
find result -type f | head -10

# Or from a flake input (no clone needed)
nix build github:MadByteDE/SPT-Linux-Guide#legacyPackages.x86_64-linux.sptMods.sain

# Even nicer once the overlay is active in your config:
#   nix build nixpkgs#sptMods.sain
# (or just use pkgs.sptMods.sain in your expressions)
```

The HM module does the equivalent of the rsync for you automatically on activation (see the `applySptMods` activation script and `resolveModClosure`).

When you change `spt-mods.nix` hashes or add mods, the builds are pure and will fail fast on bad hashes.

## Notes / gotchas

- We deliberately do **not** try to package the entire SPTarkov tree. The proprietary + user-writable parts stay in `~/Games/SPTarkov` (or wherever `spt-path` / `SPTARKOV_PATH` points). We only package the *tools* and *mod file trees*.
- The archive unpack in `mkSptMod` mirrors what the bash installer does (`7zz x -o...` or `tar -xf`).
- The rsync in the HM activation uses `--ignore-existing` to match the "don't overwrite user changes" spirit of the original `-aoa` (always overwrite? wait, actually the installer uses -aoa which *does* overwrite; the module is conservative on purpose).
- `self.supportedSptVersion` etc. live under `lib` on the final flake outputs (and under the top-level attrs when you `import ./nix`).

Happy hacking. Changes here should keep `flake.nix` short.
