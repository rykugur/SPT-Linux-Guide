# launch-server.sh

Small helper script (v2025.11-2) used primarily by the Lutris "official" and additions installers.

**Raw source**: [[raw/launch-server.sh]]

## Purpose
- Launched as pre-launch script (or manually) to start `SPT.Server.Linux` in a real terminal emulator before the game launcher.
- Discovers common terminals (alacritty, ghostty, foot, kitty, konsole, gnome-terminal, etc.).
- Handles Flatpak sandbox case with `flatpak-spawn --host` (important for Flatpak Lutris users).
- Prevents multiple server instances.

## Key Logic
- Checks for existing `SPT.Server.Linux` pid via `m_run pidof`.
- Loops through `TERMINALS` array, `cd`s to the SPT dir, runs the server in the first available terminal.
- `m_run` wrapper: if inside Flatpak sandbox (`FLATPAK_SANDBOX_DIR`), prefixes with `flatpak-spawn --host`.

## NixOS / Linux Notes
- On NixOS with native Lutris (not Flatpak), the flatpak-spawn path is not taken.
- Users following the PR#14 advice often disable the pre-launch script in Lutris and run the server as a separate native game entry or directly via the script in their terminal of choice.
- See [[nixos-support]] for the recommended split (client via additions/Lutris + native server).

## Related
- Used in Lutris installer YAMLs.
- [[spt-additions-script]] (install_spt, shortcut creation, server shortcuts).
- [[nixos-support]] (Lutris-specific tweaks on NixOS).
