# PowerShell Profile Setup - AI Agent Instructions

## Project Overview

This is a **PowerShell profile management system** for Windows Terminal, not a general-purpose application. It consists of:
- `Microsoft.PowerShell_profile.ps1` - The actual PowerShell profile that loads on every shell session
- `install.ps1` - One-time setup script that installs tools via winget and copies the profile
- `update.ps1` - Maintenance script for updating installed packages and themes

## Architecture & Key Patterns

### Installation Flow (Critical Path)
1. `install.ps1` runs as Administrator → installs dependencies via `winget`
2. Downloads Oh My Posh theme (`pure.omp.json`) to profile directory (`~\Documents\PowerShell\`)
3. Backs up existing profile → copies `Microsoft.PowerShell_profile.ps1` to `$PROFILE` location
4. Profile loads automatically on every new PowerShell session

**Key Decision**: Theme is downloaded locally (not loaded from URL) for faster startup and offline availability.

### Profile Loading Order (Microsoft.PowerShell_profile.ps1)
1. Import modules (posh-git, Terminal-Icons, PSReadLine)
2. Initialize Oh My Posh with local theme (fallback to URL if missing)
3. Initialize conditional tools (fnm, zoxide) only if installed
4. Configure PSReadLine for predictive IntelliSense
5. Define aliases, functions, and custom PSDrives

### Dependency Management
- **Winget packages**: Installed system-wide via `Install-App` function
- **PowerShell modules**: Installed per-user via `Install-Module -Scope CurrentUser`
- **Conditional initialization**: Tools like `fnm` and `zoxide` are only initialized if present (no hard failures)

## Project-Specific Conventions

### Error Handling Pattern
```powershell
# Always use -ErrorAction SilentlyContinue for optional tools
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}
```
This ensures the profile loads successfully even if optional tools are missing.

### Path Resolution Pattern
```powershell
# Always resolve paths relative to $PROFILE directory
$profileDir = Split-Path $PROFILE -Parent
$themePath = "$profileDir\pure.omp.json"
```
Never hardcode paths like `~\Documents\PowerShell\` because `$PROFILE` location varies by PowerShell edition.

### Backup Strategy
Backup existing files with timestamp before overwriting:
```powershell
$backup = "$PROFILE.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $PROFILE $backup
```

## Developer Workflows

### Testing Changes to the Profile
1. Edit `Microsoft.PowerShell_profile.ps1` in the repo
2. Run `. $PROFILE` in an open terminal to reload (faster than restart)
3. For full testing: `Copy-Item Microsoft.PowerShell_profile.ps1 $PROFILE -Force` then open new terminal

### Adding New Dependencies
1. Add package ID to arrays in both `install.ps1` and `update.ps1`
2. If it's a module: add to `$modules` array
3. If it's a winget app: add to `$packages` array and `Install-App` calls
4. Update the profile to use the new tool (follow conditional initialization pattern)

### Modifying Oh My Posh Theme
- Theme file: `pure.omp.json` (downloaded from JanDeDobbeleer/oh-my-posh repo)
- Change theme: Update `$themeUrl` in both `install.ps1` and `update.ps1`
- Local customization: Edit the downloaded `pure.omp.json` directly (will be overwritten on `update.ps1`)

## Critical Dependencies & Constraints

- **Requires**: Windows 10/11, PowerShell 7+, winget
- **Administrator required**: Only for `install.ps1` (winget installs to Program Files)
- **Execution policy**: Must allow local scripts (`Set-ExecutionPolicy -ExecutionPolicy RemoteSigned`)
- **Font dependency**: Functions using icons (eza, oh-my-posh) require 'Cascadia Code Nerd Font'

## Common Gotchas

1. **PATH not updated immediately**: After winget installs, `$env:PATH` must be refreshed manually or terminal restarted
2. **Module import failures**: If modules fail to load, check `Get-Module -ListAvailable` to verify installation
3. **Oh My Posh not rendering**: User hasn't set terminal font to a Nerd Font in Windows Terminal settings
4. **Profile doesn't load changes**: User edited the repo file but didn't copy it to `$PROFILE` location

## File Modification Guidelines

### When editing install.ps1 or update.ps1:
- Always update both files when adding/removing dependencies
- Maintain the numbered section comments for clarity
- Keep the "Install" vs "Update" verb consistency (Install-Module vs Update-Module)

### When editing Microsoft.PowerShell_profile.ps1:
- Add `# --- Section Name ---` headers for new logical groupings
- Place new aliases/functions near related ones
- Always use `Get-Command -ErrorAction SilentlyContinue` for optional tool checks
- Test that profile loads without errors even if tools are missing
