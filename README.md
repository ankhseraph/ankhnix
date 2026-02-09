>  [!NOTE]
> This README was written with the assistance of and largely by an LLM. I have checked essentially everything and added notes where relevant.
> The actual configuration is entirely configured by myself. I use LLMs to assist (as most coders should). Essentially every line of code is written by myself. It is entirely a passion project of mine that I have become quite proud of.
> For even more transparency, yes, I use Claude Code. This is mostly for doing tasks like cleaning up formatting, rearranging files, removing stupid comments, searching for conflicts etc.

# Kuraokami — NixOS Configuration

Personal NixOS flake configuration for a daily-driven desktop. Prioritizes minimalism, privacy, security hardening, impermanence, and a functional riced Sway environment.

---

## System Overview

| Component | Detail |
|---|---|
| **Host** | `kuraokami` |
| **User** | `ankhangel` |
| **OS** | NixOS 25.11 (stable) |
| **Kernel** | Linux Zen |
| **WM** | Sway (Wayland) |
| **Shell** | Zsh |
| **Terminal** | Alacritty |
| **CPU** | AMD (Ryzen) |
| **GPU** | AMD (overdrive enabled) |
| **Audio** | Pipewire + JACK |
| **Root** | Impermanent (ephemeral) |

---

## Installation

### 1. Clone the repository

```bash
git clone git@codeberg.org:ankhseraph/kuraokami.git ~/.nix
cd ~/.nix
```

### 2. Adapt hardware configuration

Replace `hardware/hardware-configuration.nix` with your own:

```bash
nixos-generate-config --show-hardware-config > hardware/hardware-configuration.nix
```

Review `hardware/tweaks.nix` and adjust GPU/CPU settings for your hardware.

### 3. Set up impermanence

This configuration uses **impermanence** with a persistent root at `/persist`. You'll need to:

1. Create a `/persist` directory on your filesystem
2. Configure your filesystem to wipe root on reboot (e.g., tmpfs root or Btrfs with rollback)
3. Review `system/core/impermanence.nix` and adjust persisted paths for your needs

If you **don't want impermanence**, comment out the impermanence configuration in `system/core/impermanence.nix` or remove it from `system/default.nix`.

### 4. Create secrets configuration

The system uses a centralized `secrets.nix` file (gitignored) for all sensitive data:

```bash
cp ~/.nix/secrets.nix.example ~/.nix/secrets.nix
nano ~/.nix/secrets.nix
```

Fill in your NAS credentials and any other secrets. The CIFS credentials file is automatically generated in `/etc/nas-credentials` during rebuild.

Skip this if you don't need the NAS mount — remove or comment out `system/network/storage.nix` from `system/default.nix`.

### 5. Update user-specific values

Before building, review and update the following for your setup:

- `flake.nix` — `username` variable (line 19) to set your username throughout the config
- `configuration.nix` — `hashedPassword` (generate with `mkpasswd`)
- `system/network/base.nix` — hostname
- `secrets.nix` — NAS credentials and other secrets
- `home/desktop/sway.nix` — monitor outputs, modes, and positions
- `system/services/backups.nix` — backup source/destination paths (if needed)
- `system/core/impermanence.nix` — persisted directories and files (if needed)

### 6. Build and switch

```bash
sudo nixos-rebuild switch --flake ~/.nix/#kuraokami --impure
```

The `--impure` flag is required because the flake imports gitignored secrets.

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
    impermanence.nix         # Persistence rules for /persist (directories, files, per-user state)
  desktop/
    sway.nix                 # Sway + XWayland enable, OZONE_WL, xdg-desktop-portal-wlr
    fonts.nix                # JetBrains Mono, Noto (with Nerd Font variants)
    xdg.nix                  # XDG portal configuration
  hardware/
    gpu.nix                  # LACT daemon + hardened systemd service config (declarative)
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
    waybar/                  # Status bar config, CSS, and LACT profile switching script
    mako.nix                 # Notification daemon
    theme.nix                # GTK theme
    packages.nix             # bemenu, pavucontrol, mpv, grim, slurp, hyprpicker, wl-clipboard
  shell/
    zsh/zsh.nix              # Zsh config with aliases and nix-commit function
    zsh/prompt.zsh           # Zsh custom prompt
    zsh/nix-commit.zsh       # nix-commit function (rebuild → commit → push)
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
| `impermanence` | `master` |

Unstable packages are accessed via `pkgs.unstable` (passed through `specialArgs`). Currently used for: Mesa, Vulkan loader, Feishin.

---

## Impermanence

This system uses **impermanence** with ephemeral root and persistent storage at `/persist`.

### What's Persisted

**System-level:**
- `/var/lib/nixos` — NixOS state
- `/var/lib/systemd` — systemd state
- `/var/log` — system logs
- `/etc/ssh` — SSH host keys
- `/var/lib/NetworkManager` — network connections
- `/etc/machine-id` — machine identifier

**User-level (ankhangel):**
- `nix-config` — this repository
- `Downloads`, `Documents`, `Pictures`, `Videos` — user files
- `.ssh`, `.gnupg`, `.local/share/keyrings` — credentials
- `.mozilla`, `.librewolf` — browser profiles
- `.config/Proton`, `.config/vesktop`, `.config/FreeTube` — app configs
- `.local/share/Steam` — game library
- `.local/share/nvim`, `.local/state/nvim` — Neovim state
- `.gitconfig` — Git configuration

### What's Ephemeral (resets on reboot)

- Everything in `/` not explicitly persisted
- `/tmp` (tmpfs)
- All caches (mesa shaders, fontconfig, etc.)
- LACT GPU config (resets to MID profile via declarative config)
- EasyEffects settings (managed declaratively)
- Shell history (intentionally ephemeral)
- Browser caches and temporary files

This approach ensures a clean, reproducible system state on every boot while preserving essential data.

---

## Daily Workflow

### Rebuild

```bash
# Manual
sudo nixos-rebuild switch --flake ~/.nix/#kuraokami --impure

# Automated (rebuild + git commit + push)
nix-commit
```

The `--impure` flag is required to access gitignored secrets.

`nix-commit` is a Zsh function that:
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

GPU profiles (LOW/MID/MAX) are managed declaratively via LACT. The config is defined in `system/hardware/lact/config.yaml` and deployed via `environment.etc`.

- **Default profile:** MID (set on every boot)
- **Runtime switching:** `Super+Z/X/C` (triggers Waybar refresh via `pkill -RTMIN+8 waybar`)
- **Profile persistence:** None — always resets to MID on reboot (ephemeral by design)

---

## Hardware Configuration

### GPU

- AMD GPU with overdrive enabled (`hardware.amdgpu.overdrive.enable = true`)
- Mesa sourced from `nixos-unstable`
- 32-bit graphics support enabled (for Steam/Proton)
- Full AMD feature mask: `amdgpu.ppfeaturemask=0xffffffff`
- Runtime management via LACT daemon with declarative config and hardened systemd service
- Config resets to MID profile on every boot

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
- Hardened LACT systemd service (limited capabilities, restricted namespaces)

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

- Root: Impermanent (ephemeral)
- Persistent data: `/persist` (bind mount or separate partition)
- Boot: VFAT (`/boot`)
- No swap — zramSwap with zstd at 50% of RAM
- tmpfs for `/tmp` (ephemeral)
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
| `vpnissue` | Debug ProtonVPN connection (`ip -s link show proton0 && sudo wg show`) |
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
