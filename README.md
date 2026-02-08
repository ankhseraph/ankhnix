> [!NOTE]
> This README was written with the assistance of and largely by an LLM. I have checked essentially everything and added notes where relevant.
> The actual configuration is entirely configured by myself. I use LLMs to assist (as most coders should). Essentially every line of code is written by myself. It is entirely a passion project of mine that I have become quite proud of.
> For even more transparency, yes, I use Claude Code. This is mostly for doing tasks like cleaning up formatting, rearranging files, removing stupid comments, searching for conflicts etc.

# Kuroakami — NixOS Configuration

Personal NixOS flake configuration for a daily-driven desktop. Prioritizes minimalism, privacy, security hardening, and a functional riced Sway environment.

---

## System Overview

| Component | Detail |
|---|---|
| **Host** | `kuraokami` |
| **User** | `ankhangel` |
| **OS** | NixOS 25.11 (stable) |
| **Kernel** | Linux Zen |
| **WM** | Sway (Wayland) |
| **Shell** | Zsh (default), Fish |
| **Terminal** | Alacritty |
| **CPU** | AMD (Ryzen) |
| **GPU** | AMD (overdrive enabled) |
| **Audio** | Pipewire + JACK |

---

## Installation

### 1. Clone the repository

```bash
git clone git@codeberg.org:ankhseraph/nix-desktop.git ~/.nix
cd ~/.nix
```

### 2. Adapt hardware configuration

Replace `hardware/hardware-configuration.nix` with your own:

```bash
nixos-generate-config --show-hardware-config > hardware/hardware-configuration.nix
```

Review `hardware/tweaks.nix` and adjust GPU/CPU settings for your hardware.

### 3. Create credentials file (NAS)

The NAS mount at `/mnt/nas` reads credentials from `./credentials` (gitignored):

```bash
nano ~/.nix/credentials
```

```
username=your_username
password=your_password
```

```bash
chmod 600 ~/.nix/credentials
```

Skip this if you don't need the CIFS mount — remove or comment out `system/network/storage.nix` from `system/default.nix`.

### 4. Update user-specific values

Before building, review and update the following for your setup:

- `configuration.nix` — `hashedPassword` (generate with `mkpasswd`)
- `system/network/base.nix` — hostname
- `system/network/storage.nix` — NAS IP and share path
- `home/desktop/sway.nix` — monitor outputs, modes, and positions
- `system/services/backups.nix` — backup source/destination paths

### 5. Build and switch

```bash
sudo nixos-rebuild switch --flake ~/.nix/#kuraokami
```

---

## Repository Structure

```
flake.nix                    # Inputs and nixosConfigurations output
configuration.nix            # Root: locale, user, zram, environment
hardware/
  hardware-configuration.nix # Auto-generated; machine-specific
  tweaks.nix                 # AMD microcode, GPU overdrive, Mesa (unstable), Vulkan
system/
  core/
    boot.nix                 # Zen kernel, systemd-boot, kernel params, sysctl hardening
    nix.nix                  # Flakes, GC (10d), store optimization, allowed-users
    packages.nix             # System packages; unfree allowlist (steam, claude-code)
  desktop/
    sway.nix                 # Sway + XWayland enable, OZONE_WL, xdg-desktop-portal-wlr
    fonts.nix                # JetBrains Mono, Noto (with Nerd Font variants)
    xdg.nix                  # XDG portal configuration
  hardware/
    gpu.nix                  # LACT daemon + hardened systemd service config
    audio.nix                # Pipewire/ALSA/JACK, low-latency tuning, USB audio fix
    cpu.nix                  # scx_lavd scheduler, ananicy-rules-cachyos
    lact/config.yaml         # LACT GPU profile definitions (LOW/MID/MAX)
  network/
    base.nix                 # NetworkManager, systemd-resolved, firewall (WireGuard UDP 51820)
    storage.nix              # CIFS automount at /mnt/nas
  services/
    system.nix               # Polkit, libinput, dbus; display-manager and coredump disabled
    flatpak.nix              # Flatpak support
    backups.nix              # Systemd user timer: daily rsync of LibreWolf profile to NAS
    privacy.nix              # Disable NM connectivity checks, geoclue2, GNOME services, PackageKit
home/
  home.nix                   # Home-manager entry; imports all home modules
  desktop/
    sway.nix                 # Monitors, inputs, keybinds, colors, autostart, workspace assignment
    waybar/                  # Status bar config and CSS
    mako.nix                 # Notification daemon
    theme.nix                # GTK theme
    packages.nix             # bemenu, pavucontrol, mpv, grim, slurp, hyprpicker, wl-clipboard
  shell/
    zsh/zsh.nix              # Zsh config
    zsh/nix-commit.zsh       # nix-commit function (rebuild → commit → push)
    fish.nix                 # Fish config, prompt, nix-commit function, fastfetch on start
    alacritty.nix            # Terminal emulator
    environment.nix          # Telemetry opt-out env vars
    packages.nix             # Shell utilities
  programs/
    packages.nix             # LibreWolf, FreeTube, OBS, Audacity, GIMP, Signal, etc.
    neovim/config.nix        # Neovim setup
    btop.nix / vesktop.nix / steam.nix / asunder.nix / easyeffects.nix
  dev/
    packages.nix             # Rust toolchain (rustc, cargo, rust-analyzer, clippy, rustfmt), claude-code
    claudecode.nix           # Claude Code config (telemetry disabled)
```

---

## Flake Inputs

| Input | Channel |
|---|---|
| `nixpkgs` | `nixos-25.11` (stable) |
| `unstable` | `nixos-unstable` |
| `home-manager` | `release-25.11` |

Unstable packages are accessed via `pkgs.unstable` (passed through `specialArgs`). Currently used for: Mesa, Vulkan loader, Feishin.

---

## Daily Workflow

### Rebuild

```bash
# Manual
sudo nixos-rebuild switch --flake ~/.nix/#kuraokami

# Automated (rebuild + git commit + push)
nix-commit
```

`nix-commit` is available in both Fish and Zsh. It:
1. Shows `git diff --stat` of pending changes
2. Runs `nixos-rebuild switch --show-trace`, logging to `/tmp/nix-build-log`
3. On success: commits with message `Rebuild: <gen> (<date> <time>)` and pushes to `origin/main`
4. On failure: prints the error

### Update flake inputs

```bash
nix flake update ~/.nix
nix-commit
```

---

## Desktop

### Monitor Layout

| Output | Resolution | Refresh | Position | Workspaces |
|---|---|---|---|---|
| `DP-1` | 2560×1440 | 120 Hz | 0,0 | 1 |
| `HDMI-A-1` | 1920×1080 | 71.92 Hz | 2560,380 | 2 |
| `HDMI-A-2` | 1920×1080 | 60 Hz | 300,1440 | 3 |

> HDMI-A-2 is my graphics tablet.

### Key Bindings (Sway)

| Binding | Action |
|---|---|
| `Super+Q` | Open terminal (Alacritty) |
| `Super+Tab` | Open LibreWolf |
| `Super+G` | Open LibreWolf (LLM profile) |
| `Ctrl+Enter` | App launcher (j4-dmenu + bemenu) |
| `Ctrl+Backspace` | Run launcher (bemenu-run) |
| `Alt+C` | Close window |
| `Alt+V` | Toggle floating |
| `Alt+F` | Toggle fullscreen |
| `Super+J` | Toggle split layout |
| `Super+M` | Exit Sway |
| `Super+Z/X/C` | Set GPU profile LOW/MID/MAX |
| `Print` | Screenshot to clipboard (slurp region) |
| `Super+P` | Color picker (hyprpicker) |
| `Super+WASD` | Focus direction |
| `Super+Shift+WASD` | Move window |
| `Super+1–0` | Switch workspace |
| `Super+Ctrl+1–0` | Move to workspace |

### GPU Profile Switching

GPU profiles (LOW/MID/MAX) are managed by LACT and toggled via `Super+Z/X/C`. Switching also sends a signal to refresh Waybar (`pkill -RTMIN+8 waybar`).

---

## Hardware Configuration

### GPU

- AMD GPU with overdrive enabled (`hardware.amdgpu.overdrive.enable = true`)
- Mesa sourced from `nixos-unstable`
- 32-bit graphics support enabled (for Steam/Proton)
- Full AMD feature mask: `amdgpu.ppfeaturemask=0xffffffff`
- Runtime management via LACT daemon with hardened systemd service

### Audio

- Pipewire with ALSA and JACK support
- ALSA auto-suspend disabled
- USB audio devices force-enabled (`snd_usb_audio use_vmalloc=1`)
- Low-latency tuning: 48 kHz, quantum 2048, allowed rates 44100/48000
- rtkit for real-time scheduling

### CPU

- sched_ext with `scx_lavd` scheduler
- ananicy with CachyOS rules for process priority management

---

## Security & Hardening

### Kernel Parameters

- `pti=on` — Page Table Isolation
- `vsyscall=none` — Disable legacy vsyscall
- `init_on_alloc=1` — Zero memory on allocation
- `slab_nomerge` — Prevent slab cache merging
- `page_alloc.shuffle=1` — Randomize page allocator freelist

### Blacklisted Kernel Modules

`dccp`, `sctp`, `rds`, `tipc` (unused network protocols), `uvcvideo` (webcam), `btusb`/`bluetooth`

### Sysctl

- Reverse path filtering enabled (`rp_filter=2`)
- ICMP/IPv6 redirects disabled
- Filesystem protections: symlinks, hardlinks, regular files, FIFOs

### Other

- Root login disabled (`hashedPassword = "!"`)
- Sudo requires password; wheel-only
- `protectKernelImage = true`
- Display manager and coredump disabled
- `execWheelOnly = true` for sudo

---

## Privacy

- NetworkManager connectivity checks disabled
- GeoClue2 location service disabled
- GNOME keyring, tracker (tinysparql/localsearch) disabled
- PackageKit disabled
- Telemetry opt-out for: DOTNET, PowerShell, Azure CLI, `DO_NOT_TRACK=1`
- Additional opt-outs in `home/shell/environment.nix`: Homebrew, NextJS, Gatsby, Stripe, SAM CLI, and others
- Claude Code telemetry explicitly disabled

---

## Storage & Backup

- Root: EXT4 (`/dev/disk/by-uuid/...`)
- Boot: VFAT (`/boot`)
- No swap — zramSwap with zstd at 50% of RAM
- tmpfs for `/tmp` (8 GB limit)
- NAS: CIFS automount at `/mnt/nas` (SMB 3.1.1, idle-timeout 60s)
- Daily systemd user timer backs up `~/.librewolf/` to `/mnt/nas/librewolf-backup/` via rsync

---

## Networking

- NetworkManager with systemd-resolved
- Hostname: `kuraokami`
- Firewall enabled; UDP 51820 open (WireGuard)
- WireGuard tools and ProtonVPN GUI installed system-wide

---

## Useful Aliases

| Alias | Command |
|---|---|
| `snvim` | `sudo -E nvim` |
| `nvfx` | `nvim .` |
| `nasmount` | Manual CIFS mount for NAS |
| `sysd-ui` | `systemd-manager-tui` |
| `bright` | SSH toggle for home server display backlight |

---

## Adding Packages

| Category | File |
|---|---|
| System-wide | `system/core/packages.nix` |
| Desktop apps | `home/desktop/packages.nix` |
| User programs | `home/programs/packages.nix` |
| Dev tools | `home/dev/packages.nix` |
| Unfree packages | Add to `allowUnfreePredicate` in `system/core/packages.nix` |
| Unstable packages | Use `unstable.pkgName` (available via `specialArgs`) |
