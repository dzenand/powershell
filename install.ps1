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
Install-App Schniz.fnm

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
# 5. Copy Optimized Profile
# -------------------------------

$sourceProfile = Join-Path $PSScriptRoot "Microsoft.PowerShell_profile.ps1"

if (Test-Path $sourceProfile) {
    Write-Host "Copying profile from $sourceProfile to $PROFILE" -ForegroundColor Cyan
    Copy-Item -Path $sourceProfile -Destination $PROFILE -Force
    Write-Host "Profile copied successfully" -ForegroundColor Green
}
else {
    Write-Host "Warning: Source profile not found at $sourceProfile" -ForegroundColor Yellow
    Write-Host "Please ensure Microsoft.PowerShell_profile.ps1 is in the same directory as install.ps1" -ForegroundColor Yellow
}

# -------------------------------
# 6. Final Message
# -------------------------------

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "Restart Windows Terminal and set your font to 'Cascadia Code Nerd Font'." -ForegroundColor Cyan
