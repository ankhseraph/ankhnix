# Kuraokami — NixOS Configuration

Personal NixOS flake for the host `kuraokami`: a Wayland/Sway desktop tuned for low-latency audio, AMD GPU control (LACT), and a minimal, privacy‑conscious setup.

## System Summary
- **Host**: `kuraokami` (hostname set in `system/network/base.nix`)
- **User**: configured via `username` in `flake.nix`
- **NixOS**: `25.11` (stateVersion in `configuration.nix`)
- **Kernel**: `linux-zen`
- **WM**: Sway (Wayland + XWayland)
- **Shell/Terminal**: Zsh + Alacritty
- **Audio**: PipeWire + JACK (low‑latency tuning)
- **VPN**: Mullvad
- **GPU Control**: LACT with declarative config

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
sudo nixos-rebuild switch --flake ~/nix-config/#kuraokami
sudo nixos-rebuild switch --flake ~/nix-config/#kuraokami --show-trace
nix flake update ~/nix-config
```
- `nix-commit` (Zsh function) runs a rebuild, commits, and pushes if successful.

## Secrets (Agenix)
Secrets are encrypted with agenix and stored in the repo:
- **Mapping**: `secrets/secrets.nix` defines which keys can decrypt which files.
- **Ciphertext**: `secrets/*.age` (e.g., `ssh-codeberg.age`, `nas-credentials.age`, `user-password.age`).
- **Identity**: `/etc/age/key.txt` (provided by you during install; referenced by `system/secrets.nix`).

`system/secrets.nix` wires these into the system (e.g., `/etc/nas-credentials`, user password hash, SSH key).

## Installation (Fresh Install)
`install.sh` uses disko on `/dev/nvme0n1` and then installs the flake:
- **Disk layout**: EFI (`/boot`) + ext4 root (`/`).
- **Command**: `sudo ./install.sh` from a NixOS live ISO after cloning.
- **Age key**: you can paste the key when prompted or place it manually at `/etc/age/key.txt`.

Review `hardware/disko.nix` before running; it will wipe the target disk.

## Notable Configuration
- **Boot/security**: hardened kernel params, blacklisted modules, `protectKernelImage = true`.
- **Audio**: rtkit with `--no-canary`, PipeWire quantum tuning, USB audio power fix.
- **CPU scheduling**: `scx_lavd` + ananicy rules.
- **GPU**: LACT daemon with hardened service and config in `system/hardware/lact/config.yaml`.
- **Network**: NetworkManager + systemd‑resolved, firewall open for WireGuard UDP `51820` and TCP `10206`.
- **Storage**: CIFS NAS mount at `/mnt/nas` using agenix-managed credentials.

## Desktop
- **Outputs**: `DP-1`, `DP-2`, `HDMI-A-2` with per-output placement and workspace mapping.
- **Waybar**: custom modules and scripts in `home/desktop/waybar/`.
- **Keybinds**: defined in `home/desktop/sway.nix` (launchers, media, volume, workspace mgmt).

## Adding Packages
- **System packages**: `system/core/packages.nix`
- **Desktop/home apps**: `home/desktop/packages.nix`, `home/programs/packages.nix`
- **Dev tools**: `home/dev/packages.nix`
- **Unfree allowlist**: `system/core/packages.nix`
- **Unstable packages**: via `pkgs.unstable.<name>` (e.g., OpenRazer, Vesktop)
