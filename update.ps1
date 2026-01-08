Write-Host "=== Updating Power Developer Terminal Dependencies ===" -ForegroundColor Cyan

# -------------------------------
# 1. Update Winget Packages
# -------------------------------

$packages = @(
    "Microsoft.PowerShell",
    "Git.Git",
    "JanDeDobbeleer.OhMyPosh",
    "NerdFonts.CascadiaCode",
    "eza-community.eza"   
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
    "PSReadLine"
)

foreach ($m in $modules) {
    Write-Host "Updating module: $m"
    Update-Module $m -Force -ErrorAction SilentlyContinue
}

# -------------------------------
# 3. Update Oh My Posh Themes
# -------------------------------

Write-Host "Updating Oh My Posh themes..."
oh-my-posh get themes --update

# -------------------------------
# 4. Final Message
# -------------------------------

Write-Host "`n=== Update Complete ===" -ForegroundColor Green
Write-Host "Restart Windows Terminal to apply theme updates." -ForegroundColor Cyan
