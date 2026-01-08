Write-Host "=== Power Developer Terminal Setup ===" -ForegroundColor Cyan

# -------------------------------
# 1. Install Dependencies
# -------------------------------

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget is required but not found. Update Windows to enable Winget." -ForegroundColor Red
    exit 1
}

function Install-App {
    param($id)
    Write-Host "Installing $id..."
    winget install --id $id -e --source winget
}

Install-App Microsoft.PowerShell
Install-App Git.Git
Install-App JanDeDobbeleer.OhMyPosh
Install-App NerdFonts.CascadiaCode
Install-App eza-community.eza
Install-App nepnep.neofetch-win

# -------------------------------
# 2. Install PowerShell Modules
# -------------------------------

$modules = @(
    "posh-git",
    "Terminal-Icons",
    "PSReadLine"
)

foreach ($m in $modules) {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing module: $m"
        Install-Module $m -Scope CurrentUser -Force
    } else {
        Write-Host "Module already installed: $m"
    }
}

# -------------------------------
# 3. Oh My Posh Theme Selector
# -------------------------------

$themePath = $env:POSH_THEMES_PATH
$themes = Get-ChildItem $themePath -Filter *.omp.json | Select-Object -ExpandProperty Name

Write-Host "`nAvailable Oh My Posh Themes:" -ForegroundColor Cyan
$themes | ForEach-Object { Write-Host " - $_" }

Write-Host "`nEnter theme name to use (default: pure.omp.json):" -ForegroundColor Yellow
$selectedTheme = Read-Host

if ([string]::IsNullOrWhiteSpace($selectedTheme)) {
    $selectedTheme = "pure.omp.json"
}

if (-not ($themes -contains $selectedTheme)) {
    Write-Host "Theme not found. Falling back to pure.omp.json" -ForegroundColor Yellow
    $selectedTheme = "pure.omp.json"
}

Write-Host "Using theme: $selectedTheme" -ForegroundColor Green

# -------------------------------
# 4. Backup Existing Profile
# -------------------------------

if (Test-Path $PROFILE) {
    $backup = "$PROFILE.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $PROFILE $backup
    Write-Host "Existing profile backed up to $backup" -ForegroundColor Yellow
} else {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# -------------------------------
# 5. Write New Optimized Profile
# -------------------------------

$profileContent = @"
# ============================
#  Power Developer Profile
#  Clean, Fast, Modular
# ============================

# --- Modules ---
Import-Module posh-git
Import-Module Terminal-Icons
Import-Module PSReadLine

# --- Oh My Posh Prompt ---
oh-my-posh init pwsh --config "`$env:POSH_THEMES_PATH\$selectedTheme" | Invoke-Expression

# --- PSReadLine Enhancements ---
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# --- Aliases ---
Set-Alias ll "eza --long --icons"
Set-Alias ls eza
Set-Alias g git
Set-Alias d docker

# --- Git Helpers ---
function glog {
    git log --oneline --graph --decorate --all
}

function gclean {
    git fetch --prune
    git gc --prune=now --aggressive
}

function gprune {
    Write-Host "Fetching latest from origin..." -ForegroundColor Cyan
    git fetch --prune

    Write-Host "Finding local branches not on origin..." -ForegroundColor Cyan

    # Protected branches
    \$protected = @("main", "master", "develop")

    # Current branch
    \$current = git rev-parse --abbrev-ref HEAD

    # Branches to delete
    \$branches = git branch --format="%(refname:short)" |
        Where-Object {
            \$_ -ne \$current -and
            -not (\$protected -contains \$_) -and
            -not (git show-ref --verify --quiet "refs/remotes/origin/\$_")
        }

    if (-not \$branches) {
        Write-Host "No stale branches found." -ForegroundColor Green
        return
    }

    Write-Host "`nThe following branches no longer exist on origin:" -ForegroundColor Yellow
    \$branches | ForEach-Object { Write-Host " - \$_" }

    \$confirm = Read-Host "`nDelete these branches? (y/N)"

    if (\$confirm -eq "y") {
        foreach (\$b in \$branches) {
            git branch -D \$b
            Write-Host "Deleted \$b" -ForegroundColor Red
        }
        Write-Host "`nCleanup complete." -ForegroundColor Green
    } else {
        Write-Host "Aborted." -ForegroundColor Yellow
    }
}

# --- SQL Helpers (local dev) ---
function sqlrun {
    param([string]`$query)
    sqlcmd -S localhost -Q `"$query`"
}

# --- Navigation Shortcuts ---
function up { Set-Location .. }
function .. { Set-Location .. }
function ... { Set-Location ../.. }

# --- Environment Awareness ---
`$env:EDITOR = "code"

# --- Welcome Message ---
Write-Host "Loaded Power Developer Profile
