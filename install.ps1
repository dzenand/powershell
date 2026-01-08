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
    }
    else {
        Write-Host "Module already installed: $m"
    }
}

# -------------------------------
# 3. Oh My Posh Configuration
# -------------------------------

Write-Host "Configuring Oh My Posh with pure theme..." -ForegroundColor Cyan

# Create profile directory if it doesn't exist
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Download pure theme to profile directory
$themeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/pure.omp.json"
$themePath = "$profileDir\pure.omp.json"

Write-Host "Downloading pure theme to $themePath" -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $themeUrl -OutFile $themePath -UseBasicParsing
    Write-Host "Theme downloaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "Error downloading theme: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Falling back to default theme" -ForegroundColor Yellow
    $themePath = $null
}

# -------------------------------
# 4. Backup Existing Profile
# -------------------------------

if (Test-Path $PROFILE) {
    $backup = "$PROFILE.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $PROFILE $backup
    Write-Host "Existing profile backed up to $backup" -ForegroundColor Yellow
}
else {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# -------------------------------
# 5. Write New Optimized Profile
# -------------------------------

$profileContent = @"
# ============================
#  Power Developer Profile
# ============================

# --- Modules ---
Import-Module posh-git
Import-Module Terminal-Icons
Import-Module PSReadLine

# --- Oh My Posh Prompt ---
`$profileDir = Split-Path `$PROFILE -Parent
if (Test-Path "`$profileDir\pure.omp.json") {
    oh-my-posh init pwsh --config "`$profileDir\pure.omp.json" | Invoke-Expression
} else {
    # Fallback to URL if local file doesn't exist
    oh-my-posh init pwsh --config "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/pure.omp.json" | Invoke-Expression
}

# --- PSReadLine Enhancements ---
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# --- Aliases ---
function ll { eza --long --icons @args }
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
    `$protected = @("main", "master", "develop")

    # Current branch
    `$current = git rev-parse --abbrev-ref HEAD

    # Branches to delete
    `$branches = git branch --format="%(refname:short)" |
        Where-Object {
            `$_ -ne `$current -and
            -not (`$protected -contains `$_) -and
            -not (git show-ref --verify --quiet "refs/remotes/origin/`$_")
        }

    if (-not `$branches) {
        Write-Host "No stale branches found." -ForegroundColor Green
        return
    }

    Write-Host "`nThe following branches no longer exist on origin:" -ForegroundColor Yellow
    `$branches | ForEach-Object { Write-Host " - `$_" }

    `$confirm = Read-Host "`nDelete these branches? (y/N)"

    if (`$confirm -eq "y") {
        foreach (`$b in `$branches) {
            git branch -D `$b
            Write-Host "Deleted `$b" -ForegroundColor Red
        }
        Write-Host "`nCleanup complete." -ForegroundColor Green
    } else {
        Write-Host "Aborted." -ForegroundColor Yellow
    }
}

# --- SQL Helpers (local dev) ---
function sqlrun {
    param([string]`$query)
    sqlcmd -S localhost -Q "`$query"
}

# --- Navigation Shortcuts ---
function up { Set-Location .. }
function .. { Set-Location .. }
function ... { Set-Location ../.. }

# --- Custom Drives ---
New-PSDrive -Name "repos" -PSProvider FileSystem -Root "~\Repos" -Scope Global | Out-Null
function repos { Set-Location repos: }

# --- Environment Awareness ---
`$env:EDITOR = "code"

# --- Refresh PATH (ensures winget-installed tools are available) ---
`$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")

# --- Welcome Message ---
Write-Host "Loaded Power Developer Profile ✔" -ForegroundColor Cyan
"@

Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8

# -------------------------------
# 6. Final Message
# -------------------------------

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "Restart Windows Terminal and set your font to 'Cascadia Code Nerd Font'." -ForegroundColor Cyan
