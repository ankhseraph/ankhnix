# Kuraokami — NixOS Configuration

Personal NixOS flake for the host `kuraokami`: a Wayland/Sway desktop tuned for low‑latency audio, AMD GPU control (LACT), and a privacy‑conscious setup with home‑manager.

## Additional Host: homeserver
This repo also contains a headless homeserver config under `hosts/homeserver` and `modules/server`, plus a laptop config under `hosts/nidhoggr` with `modules/laptop` and `modules/laptop/home`.
Use `HOMESERVER_SETUP.md` for the single‑age‑key setup steps on the server.
Use `HOMESERVER_AGENTS.md` for the full homeserver checklist.

## System Summary (Current State)
- **Host**: `kuraokami` (hostname set in `modules/system/network/base.nix`)
- **User**: configured via `username` in `flake.nix` (propagated through `specialArgs`)
- **NixOS**: `25.11` (stateVersion in `hosts/kuraokami/system.nix` + `modules/home/home.nix`)
- **Timezone/Locale**: `Europe/Bucharest`, `en_US.UTF-8`
- **Kernel**: `linux-zen` with hardened params and extra sysctls
- **WM/Session**: Sway (Wayland + XWayland), Waybar, Mako
- **Shell/Terminal**: Zsh + Alacritty
- **Editor**: Nixvim (nixvim module via home‑manager)
- **Audio**: PipeWire + JACK with rtkit and low‑latency tuning
- **CPU scheduling**: `scx_lavd` + ananicy rules; `performance` governor
- **GPU control**: LACT service + config in `modules/system/hardware/lact/config.yaml`
- **VPN**: Mullvad
- **Secrets**: agenix + `/etc/age/key.txt`
- **Desktop apps**: Bolt Launcher wrapper (Mullvad excluded) + desktop entry on desktop/laptop profiles
- **Laptop power**: aggressive TLP battery profile (1.5 GHz cap, boost off) + logind power keys via `services.logind.settings`; laptop no longer autostarts Mullvad GUI or Blueman tray to save RAM

## Repository Structure
```
flake.nix                 # Flake inputs and nixosConfigurations
hosts/                    # Per-host config, hardware-configuration, disko
modules/                  # NixOS + home-manager modules
secrets/                  # Agenix secrets + access map
scripts/install.sh        # Disko-based install script (fresh installs)
```

## Build & Update
```bash
sudo nixos-rebuild switch --flake ~/nix-config/#kuraokami (or doas ...)
sudo nixos-rebuild switch --flake ~/nix-config/#kuraokami --show-trace (or doas ...)
nix flake update ~/nix-config
```
- `nix-commit` (Zsh function) runs a rebuild, commits, and pushes if successful.

## Secrets (Agenix)
Secrets are encrypted with agenix and stored in the repo:
- **Mapping**: `secrets/secrets.nix` defines which keys can decrypt which files.
- **Ciphertext**: `secrets/*.age` (e.g., `ssh-codeberg.age`, `nas-credentials.age`, `user-password.age`).
- **Identity**: `/etc/age/key.txt` (provided by you during install; referenced by `modules/system/secrets.nix`).

`modules/system/secrets.nix` wires these into the system (e.g., `/run/agenix/nas-credentials`, user password hash, SSH key).

Homeserver secrets include `homeserver-user-password.age`, `homeserver-navidrome-env.age`, `homeserver-searxng-env.age`, `homeserver-cloudflared-credentials.age`, and `homeserver-mscd-api-hash.age`.

## Installation (Fresh Install)
`scripts/install.sh` uses disko, generates a fresh `hardware-configuration.nix`, installs the flake, and copies this repo to the target system:
- **Disk layout**: EFI (`/boot`) + ext4 root (`/`).
- **Command**: `sudo ./scripts/install.sh` (or `doas ./scripts/install.sh`) from a NixOS live ISO after cloning.
- **Age key**: paste when prompted or place at `/etc/age/key.txt` before running.
- **Disk selection**: defaults to `/dev/nvme0n1` and will wipe the chosen disk.

Review `hosts/<host>/disko.nix` before running; it will wipe the target disk.

## Notable Configuration
- **Boot/security**: systemd‑boot, hardened kernel params, blacklisted modules, `protectKernelImage = true`, `/tmp` on tmpfs.
- **Audio**: rtkit with `--no-canary`, PipeWire quantum tuning, USB audio power fix, WirePlumber no‑suspend rules.
- **CPU scheduling**: `scx_lavd` + ananicy rules.
- **CPU governor**: `performance` via `powerManagement.cpuFreqGovernor`.
- **GPU**: LACT daemon with hardened service and config in `modules/system/hardware/lact/config.yaml`.
- **Network**: NetworkManager + systemd‑resolved (DNSSEC + DNS‑over‑TLS), firewall open for WireGuard UDP `51820` and TCP `10206`; laptop auto‑connects Mullvad on boot.
- **Privacy**: NetworkManager connectivity checks disabled; geoclue, gnome‑keyring, localsearch, tinysparql, packagekit disabled.
- **Storage**: CIFS NAS mount at `/mnt/nas` using agenix‑managed credentials and automount.

## Deep‑Dive: Where to Change What
- **Users / shell / base env**: `hosts/kuraokami/system.nix`
- **Boot params + kernel**: `modules/system/core/boot.nix`
- **Nix settings / GC**: `modules/system/core/nix.nix`
- **System packages + unfree allowlist**: `modules/system/core/packages.nix`
- **Sway system enablement**: `modules/system/desktop/sway.nix`
- **Fonts**: `modules/system/desktop/fonts.nix`
- **XDG portals**: `modules/system/desktop/xdg.nix`
- **Audio low‑latency tuning**: `modules/system/hardware/audio.nix`
- **GPU control (LACT)**: `modules/system/hardware/gpu.nix` + `modules/system/hardware/lact/config.yaml`
- **CPU scheduling**: `modules/system/hardware/cpu.nix`
- **OpenRazer**: `modules/system/hardware/openrazer.nix`
- **Network + firewall**: `modules/system/network/base.nix`
- **NAS mount**: `modules/system/network/storage.nix`
- **Privacy toggles**: `modules/system/services/privacy.nix`
- **Flatpak**: `modules/system/services/flatpak.nix`
- **Home imports**: `modules/home/home.nix`
- **Sway keybinds + outputs**: `modules/home/desktop/sway.nix`
- **Waybar config + scripts**: `modules/home/desktop/waybar/config.nix` + `modules/home/desktop/waybar/scripts/*`
- **GTK/Qt theme**: `modules/home/desktop/theme.nix`
- **Zsh config**: `modules/home/shell/zsh/zsh.nix` + `modules/home/shell/zsh/prompt.zsh`
- **Alacritty**: `modules/home/shell/alacritty.nix`
- **SSH + Codeberg key**: `modules/home/shell/ssh.nix`
- **Firefox policy + profile**: `modules/home/programs/firefox.nix`
- **Neovim (nixvim)**: `modules/home/programs/neovim/config.nix`
- **Dev toolchains**: `modules/home/dev/packages.nix`
- **Claude/Codex env**: `modules/home/dev/claudecode.nix`

## Desktop
- **Outputs**: `DP-1`, `DP-2`, `HDMI-A-2` with per‑output placement and workspace mapping.
- **Waybar**: custom modules and scripts in `home/desktop/waybar/`.
- **Sway**: custom keybinds, bemenu launcher, autotiling, and startup apps.
- **Theme**: Adwaita‑dark GTK + OLED‑style Firefox UI.

## Adding Packages
- **System packages**: `modules/system/core/packages.nix`
- **Desktop/home apps**: `modules/home/desktop/packages.nix`, `modules/home/programs/packages.nix`
- **Dev tools**: `modules/home/dev/packages.nix`
- **Unfree allowlist**: `modules/system/core/packages.nix`
- **Unstable packages**: via `pkgs.unstable.<name>` (e.g., OpenRazer, Vesktop)
