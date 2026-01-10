Write-Host "=== Updating Power Developer Terminal Dependencies ===" -ForegroundColor Cyan

# -------------------------------
# 1. Update Winget Packages
# -------------------------------

$packages = @(
    "Microsoft.PowerShell",
    "Git.Git",
    "JanDeDobbeleer.OhMyPosh",
    "NerdFonts.CascadiaCode",
    "eza-community.eza",
    "Schniz.fnm",
    "ajeetdsouza.zoxide",
    "junegunn.fzf"
)

foreach ($pkg in $packages) {
    Write-Host "Updating $pkg..."
    winget upgrade --id $pkg -e --source winget
}

# -------------------------------
# 2. Update PowerShell Modules
# -------------------------------

$modules = @(
    "posh-git",
    "Terminal-Icons",
    "PSReadLine",
    "PSFzf"
)

foreach ($m in $modules) {
    Write-Host "Updating module: $m"
    Update-Module $m -Force -ErrorAction SilentlyContinue
}

# -------------------------------
# 3. Update Oh My Posh Theme
# -------------------------------

Write-Host "Updating Oh My Posh theme..."

# Update local theme file in profile directory
$profileDir = Split-Path $PROFILE -Parent
$themeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/pure.omp.json"
$themePath = "$profileDir\pure.omp.json"

if (Test-Path $profileDir) {
    try {
        Invoke-WebRequest -Uri $themeUrl -OutFile $themePath -UseBasicParsing
        Write-Host "Theme updated successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Error updating theme: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "Profile directory not found. Run install.ps1 first." -ForegroundColor Yellow
}

# Clear Oh My Posh cache
oh-my-posh cache clear

# -------------------------------
# 4. Final Message
# -------------------------------

Write-Host "`n=== Update Complete ===" -ForegroundColor Green
Write-Host "Restart Windows Terminal to apply theme updates." -ForegroundColor Cyan
