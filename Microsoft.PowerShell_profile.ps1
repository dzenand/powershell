# ============================
#  Power Developer Profile
# ============================

# --- Modules ---
Import-Module posh-git
Import-Module Terminal-Icons
Import-Module PSReadLine
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
}

# --- Oh My Posh Prompt ---
$profileDir = Split-Path $PROFILE -Parent
if (Test-Path "$profileDir\pure.omp.json") {
    oh-my-posh init pwsh --config "$profileDir\pure.omp.json" | Invoke-Expression
}
else {
    # Fallback to URL if local file doesn't exist
    oh-my-posh init pwsh --config "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/pure.omp.json" | Invoke-Expression
}

# --- Fast Node Manager (fnm) ---
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd | Out-String | Invoke-Expression
}

# --- Zoxide (smarter cd) ---
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# --- FZF (fuzzy finder) ---
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    # Set default options for fzf
    $env:FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border'
    
    # PSFzf keybindings (if module is available)
    if (Get-Module -Name PSFzf) {
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    }
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
    $protected = @("main", "master", "develop")

    # Current branch
    $current = git rev-parse --abbrev-ref HEAD

    # Branches to delete
    $branches = git branch --format="%(refname:short)" |
    Where-Object {
        $_ -ne $current -and
        -not ($protected -contains $_) -and
        -not (git show-ref --verify --quiet "refs/remotes/origin/$_")
    }

    if (-not $branches) {
        Write-Host "No stale branches found." -ForegroundColor Green
        return
    }

    Write-Host "`nThe following branches no longer exist on origin:" -ForegroundColor Yellow
    $branches | ForEach-Object { Write-Host " - $_" }

    $confirm = Read-Host "`nDelete these branches? (y/N)"

    if ($confirm -eq "y") {
        foreach ($b in $branches) {
            git branch -D $b
            Write-Host "Deleted $b" -ForegroundColor Red
        }
        Write-Host "`nCleanup complete." -ForegroundColor Green
    }
    else {
        Write-Host "Aborted." -ForegroundColor Yellow
    }
}

# --- SQL Helpers (local dev) ---
function sqlrun {
    param([string]$query)
    sqlcmd -S localhost -Q "$query"
}

# --- Navigation Shortcuts ---
function up { Set-Location .. }
function .. { Set-Location .. }
function ... { Set-Location ../.. }

# --- Custom Drives ---
New-PSDrive -Name "repos" -PSProvider FileSystem -Root "~\Repos" -Scope Global | Out-Null
function repos { Set-Location repos: }

# --- Environment Awareness ---
$env:EDITOR = "code"

# --- Refresh PATH (ensures winget-installed tools are available) ---
$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
$env:PATH = "$userPath;$env:PATH" -split ';' | Select-Object -Unique | Join-String -Separator ';'

# --- Welcome Message ---
Write-Host "Loaded Power Developer Profile ✔" -ForegroundColor Cyan
