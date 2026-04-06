# Kuraokami — NixOS Configuration

Personal NixOS flake for the host `kuraokami`: a Wayland/Sway desktop tuned for low‑latency audio, AMD GPU control (LACT), and a privacy‑conscious setup with home‑manager.

Disclaimer: The code is mostly hand written and documented, however I do not hide my usage of LLMs. Review all changes carefully before applying.

## System Summary (Current State)
- **Host**: `kuraokami` (hostname set in `system/network/base.nix`)
- **User**: configured via `username` in `flake.nix` (propagated through `specialArgs`)
- **NixOS**: `25.11` (stateVersion in `configuration.nix` + `home/home.nix`)
- **Timezone/Locale**: `Europe/Bucharest`, `en_US.UTF-8`
- **Kernel**: `linux-zen` with hardened params and extra sysctls
- **WM/Session**: Sway (Wayland + XWayland), Waybar, Mako
- **Shell/Terminal**: Zsh + Alacritty
- **Editor**: Nixvim (nixvim module via home‑manager)
- **Audio**: PipeWire + JACK with rtkit and low‑latency tuning
- **CPU scheduling**: `scx_lavd` + ananicy rules; `performance` governor
- **GPU control**: LACT service + config in `system/hardware/lact/config.yaml`
- **VPN**: Mullvad
- **Secrets**: agenix + `/etc/age/key.txt`

## Repository Structure
```
flake.nix                 # Flake inputs and nixosConfigurations.kuraokami
configuration.nix         # Root config (users, locale, zram, env)
hardware/                 # Hardware-specific config + disko layout
system/                   # System modules (core/desktop/hardware/network/services)
home/                     # Home-manager modules (desktop/shell/programs/dev)
secrets/                  # Agenix secrets + access map
install.sh                # Disko-based install script (fresh installs)
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
- **Identity**: `/etc/age/key.txt` (provided by you during install; referenced by `system/secrets.nix`).

`system/secrets.nix` wires these into the system (e.g., `/run/agenix/nas-credentials`, user password hash, SSH key).

## Installation (Fresh Install)
`install.sh` uses disko, generates a fresh `hardware-configuration.nix`, installs the flake, and copies this repo to the target system:
- **Disk layout**: EFI (`/boot`) + ext4 root (`/`).
- **Command**: `sudo ./install.sh` (or `doas ./install.sh`) from a NixOS live ISO after cloning.
- **Age key**: paste when prompted or place at `/etc/age/key.txt` before running.
- **Disk selection**: defaults to `/dev/nvme0n1` and will wipe the chosen disk.

Review `hardware/disko.nix` before running; it will wipe the target disk.

## Notable Configuration
- **Boot/security**: systemd‑boot, hardened kernel params, blacklisted modules, `protectKernelImage = true`, `/tmp` on tmpfs.
- **Audio**: rtkit with `--no-canary`, PipeWire quantum tuning, USB audio power fix, WirePlumber no‑suspend rules.
- **CPU scheduling**: `scx_lavd` + ananicy rules.
- **CPU governor**: `performance` via `powerManagement.cpuFreqGovernor`.
- **GPU**: LACT daemon with hardened service and config in `system/hardware/lact/config.yaml`.
- **Network**: NetworkManager + systemd‑resolved (DNSSEC + DNS‑over‑TLS), firewall open for WireGuard UDP `51820` and TCP `10206`.
- **Privacy**: NetworkManager connectivity checks disabled; geoclue, gnome‑keyring, localsearch, tinysparql, packagekit disabled.
- **Storage**: CIFS NAS mount at `/mnt/nas` using agenix‑managed credentials and automount.

## Deep‑Dive: Where to Change What
- **Users / shell / base env**: `configuration.nix`
- **Boot params + kernel**: `system/core/boot.nix`
- **Nix settings / GC**: `system/core/nix.nix`
- **System packages + unfree allowlist**: `system/core/packages.nix`
- **Sway system enablement**: `system/desktop/sway.nix`
- **Fonts**: `system/desktop/fonts.nix`
- **XDG portals**: `system/desktop/xdg.nix`
- **Audio low‑latency tuning**: `system/hardware/audio.nix`
- **GPU control (LACT)**: `system/hardware/gpu.nix` + `system/hardware/lact/config.yaml`
- **CPU scheduling**: `system/hardware/cpu.nix`
- **OpenRazer**: `system/hardware/openrazer.nix`
- **Network + firewall**: `system/network/base.nix`
- **NAS mount**: `system/network/storage.nix`
- **Privacy toggles**: `system/services/privacy.nix`
- **Flatpak**: `system/services/flatpak.nix`
- **Home imports**: `home/home.nix`
- **Sway keybinds + outputs**: `home/desktop/sway.nix`
- **Waybar config + scripts**: `home/desktop/waybar/config.nix` + `home/desktop/waybar/scripts/*`
- **GTK/Qt theme**: `home/desktop/theme.nix`
- **Zsh config**: `home/shell/zsh/zsh.nix` + `home/shell/zsh/prompt.zsh`
- **Alacritty**: `home/shell/alacritty.nix`
- **SSH + Codeberg key**: `home/shell/ssh.nix`
- **Firefox policy + profile**: `home/programs/firefox.nix`
- **Neovim (nixvim)**: `home/programs/neovim/config.nix`
- **Dev toolchains**: `home/dev/packages.nix`
- **Claude/Codex env**: `home/dev/claudecode.nix`

## Desktop
- **Outputs**: `DP-1`, `DP-2`, `HDMI-A-2` with per‑output placement and workspace mapping.
- **Waybar**: custom modules and scripts in `home/desktop/waybar/`.
- **Sway**: custom keybinds, bemenu launcher, autotiling, and startup apps.
- **Theme**: Adwaita‑dark GTK + OLED‑style Firefox UI.

## Adding Packages
- **System packages**: `system/core/packages.nix`
- **Desktop/home apps**: `home/desktop/packages.nix`, `home/programs/packages.nix`
- **Dev tools**: `home/dev/packages.nix`
- **Unfree allowlist**: `system/core/packages.nix`
- **Unstable packages**: via `pkgs.unstable.<name>` (e.g., OpenRazer, Vesktop)

## AI Maintenance Reminder (Mandatory)
- If you change behavior, modules, packages, or workflow, update `README.md`, `AGENTS.md`, and `CLAUDE.md` in the same PR.
- Keep these docs concrete: mention paths, services, ports, and commands explicitly.
- If a detail drifts, fix it immediately to keep future AI guidance accurate.
