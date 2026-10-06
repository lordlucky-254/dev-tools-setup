# dev-tools-setup — developer tool installer for Windows (winget)
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1
# Idempotent: safe to re-run.

$ErrorActionPreference = "SilentlyContinue"

function Info($m)  { Write-Host "==> $m" -ForegroundColor Cyan }
function OK($m)    { Write-Host "    $m" -ForegroundColor Green }
function Warn($m)  { Write-Host "    ! $m" -ForegroundColor Yellow }

# --- winget availability ---
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found. Install 'App Installer' from the Microsoft Store, then re-run." -ForegroundColor Red
    exit 1
}

# --- core packages ---
# Format: winget package id
$WingetPackages = @(
    "Git.Git",
    "Microsoft.VisualStudioCode",
    "Neovim.Neovim",
    "GitHub.cli",
    "sharkdp.fd",
    "BurntSushi.ripgrep.MSVC",
    "jqlang.jq",
    "junegunn.fzf",
    "OpenJS.NodeJS.LTS",
    "Python.Python.3.12",
    "Rustlang.Rustup",
    "GoLang.Go",
    "EclipseAdoptium.Temurin.21.JDK",
    "Docker.DockerDesktop",
    "astral-sh.uv",
    "Microsoft.PowerShell"
)

Info "Installing packages via winget"
foreach ($pkg in $WingetPackages) {
    $installed = winget list --id $pkg --exact 2>$null | Select-String -Pattern $pkg
    if ($installed -and $LASTEXITCODE -eq 0) {
        OK "$pkg (already installed)"
    } else {
        winget install --id $pkg --exact --silent --accept-package-agreements --accept-source-agreements 2>$null
        if ($LASTEXITCODE -eq 0) { OK "$pkg" } else { Warn "skipped $pkg" }
    }
}

# --- tmux alternative on Windows: none needed (use Windows Terminal) ---
# --- extra CLI tools via npm (requires node in PATH; refresh if just installed) ---
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")

if (Get-Command npm -ErrorAction SilentlyContinue) {
    Info "npm globals"
    foreach ($g in @("typescript", "prettier", "eslint", "@anthropic-ai/claude-code")) {
        npm install -g $g 2>$null
        if ($LASTEXITCODE -eq 0) { OK $g } else { Warn "skipped $g" }
    }
} else {
    Warn "npm not in PATH yet (open a new terminal and re-run for npm globals)"
}

# --- starship prompt ---
Info "starship prompt"
if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
    winget install --id Starship.Starship --exact --silent --accept-package-agreements 2>$null
    if ($LASTEXITCODE -eq 0) { OK "installed" } else { Warn "skipped" }
    # Add to PowerShell profile
    $profilePath = $PROFILE.CurrentUserAllHosts
    if (-not (Test-Path $profilePath)) { New-Item -ItemType File -Path $profilePath -Force | Out-Null }
    $init = 'Invoke-Expression (&starship init powershell)'
    if (-not (Select-String -Path $profilePath -Pattern 'starship init' -Quiet)) {
        Add-Content -Path $profilePath -Value $init
        OK "starship added to PowerShell profile"
    }
} else { OK "already installed" }

# --- opencode ---
Info "opencode"
if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
    powershell -c "irm https://opencode.ai/install.ps1 | iex" 2>$null
    if ($LASTEXITCODE -eq 0) { OK "installed" } else { Warn "install failed - see https://opencode.ai" }
} else { OK "already installed" }

# --- checks ---
Write-Host ""
Write-Host "Done! Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open a NEW terminal (PATH updated)"
Write-Host "  2. gh auth login        -> authenticate GitHub CLI"
Write-Host "  3. nvim                 -> bootstraps plugins/LSP on first run"
Write-Host "  4. opencode             -> AI assistant ready"
Write-Host "  5. Restart if Docker Desktop was just installed"
