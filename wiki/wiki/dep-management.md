# Dependency Management in the Installer

The script tries to be self-contained for "normal" Linux desktops while still allowing system tools.

## Hard Requirements (check_native_deps)
```bash
cmds=( "python3" "curl" "7zzs" "xxd" "hpatchz" "jq" "umu-run" )
```
- If present in PATH → use it.
- If in the downloadable list (jq, hpatchz, xxd, 7zzs, umu-run) → `install_dep` downloads from `METADATA[${cmd}-url]`, extracts/renames, chmod +x, moves to `${RUNTIME_DIR}/${cmd}`.
- Then `export PATH=$RUNTIME_DIR:$PATH` so later calls find them.

`m_7z` hardcodes `7zzs`.
`m_umu` uses the resolved UMU_PATH (prefers system `umu-run`, else downloaded).

## Why This Matters on NixOS
- Many of these (jq, xxd, umu-run) are already provided by the user's gaming/home-manager profile.
- Downloading duplicates (especially umu-run zipapp or 7zzs) can work but may pull glibc-linked binaries that then have the same FHS/container problems when executed.
- Preferred: have the nix profile provide them, let the `command -v` succeed, and only fall back for truly exotic ones like the exact hpatchz version or the 7zip 26.01 standalone if `7zzs` command is wanted.

## Related Code
- `check_native_deps`, `install_dep`
- UMU_PATH resolution
- PATH export in main()
- metadata.conf for the download URLs (including the 7z 26.01 tar.xz that contains the 7zzs binary).

See [[nixos-support]] for detection + messaging proposals and [[spt-additions-script]] for call sites.
