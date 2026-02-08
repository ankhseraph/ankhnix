# Seiryu
This is my own home desktop's NixOS configuration; I drive this daily. I've included some hardening tweaks for network & kernel, customized the audio stack for my personal setup, and thoroughly riced it to be as minimalist and functional as possible.

## Installation

### 1. Clone the repository
```bash
git clone git@codeberg.org:ankhseraph/seiryu.git /etc/nixos
cd /etc/nixos
```

### 2. Create credentials file

Create a `credentials` file in `/etc/nixos/` for NAS mounting:
```bash
sudo nano /etc/nixos/credentials
```

Add your credentials:
```
username=your_username
password=your_password
```

Set proper permissions:
```bash
sudo chmod 600 /etc/nixos/credentials
```

### 3. Rebuild the system
```bash
sudo nixos-rebuild switch --flake .#ankhangel
```

## Notes

- The `credentials` file is gitignored and should never be committed
- Modify configuration files as needed for your hardware
- Run `sudo nixos-rebuild switch --flake .#ankhangel` after making changes
