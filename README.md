# dev-tools-setup

One repo to set up a full developer environment on **Linux, macOS, and
Windows** — CLI essentials, language toolchains, editors, containers, and
AI/dev extras, with idempotent installers you can re-run any time.

## Quick start

| OS      | Command                                                        |
| ------- | -------------------------------------------------------------- |
| Linux   | `curl -fsSL https://raw.githubusercontent.com/lordlucky-254/dev-tools-setup/main/install.sh \| bash` |
| macOS   | same as Linux (uses Homebrew; installs it if missing)         |
| Windows | `irm https://raw.githubusercontent.com/lordlucky-254/dev-tools-setup/main/install.ps1 \| iex` |

Or clone and run locally (recommended — lets you review first):

```bash
git clone https://github.com/lordlucky-254/dev-tools-setup.git
cd dev-tools-setup
bash install.sh          # Linux / macOS
```

```powershell
git clone https://github.com/lordlucky-254/dev-tools-setup.git
cd dev-tools-setup
powershell -ExecutionPolicy Bypass -File install.ps1   # Windows
```

## What gets installed

### CLI essentials
git, curl, wget, zsh, tmux, ripgrep, fd, fzf, jq, GitHub CLI (`gh`),
tree, htop, unzip, make/cmake, gcc/g++, gdb

### Language toolchains
| Language | Method                          |
| -------- | ------------------------------- |
| Node.js  | nvm (latest LTS)                |
| Python   | uv (fast installer + venv tool) |
| Rust     | rustup (stable)                 |
| Go       | system package / winget         |
| Java     | OpenJDK 21+                     |

### Editors & platforms
- **Neovim** (plugins/LSP bootstrap on first run)
- **VS Code**
- **Docker** (engine + compose)
- **GitHub CLI** (`gh auth login` to authenticate)

### Extras
- **starship** prompt
- **opencode** AI assistant (`opencode --version`)

## Per-platform notes

- **Linux** — detects `dnf` (Fedora/RHEL), `apt` (Debian/Ubuntu),
  `pacman` (Arch), or `zypper` (openSUSE) and installs native packages
  first.
- **macOS** — installs Homebrew if you don't have it, then uses it.
- **Windows** — uses `winget`; run in PowerShell 5.1+.
- Packages that don't exist in your distro repo are skipped with a
  warning, not an error.

## Customizing

Edit the arrays at the top of each script:

- `install.sh` → `DNF_PKGS`, `APT_PKGS`, `PACMAN_PKGS`, `BREW_PKGS`
- `install.ps1` → `$WingetPackages`

Then refresh this README's tool list and open a PR.

## Verifying a fresh install

```bash
git --version && nvim --version | head -1 && node -v && python3 -V \
  && rustc --version && go version && docker --version && gh --version
```
