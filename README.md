# Power Developer Terminal Setup

A clean, modern PowerShell + Windows Terminal setup for developers.

## Contents

- `install.ps1` – Installs all dependencies and copies your PowerShell profile.
- `update.ps1` – Updates all installed tools and modules.

## Installation

1. Open PowerShell 7 as Administrator.
2. Run:

   ```pwsh
   ./install.ps1
   ```

3. Restart Windows Terminal and set your font to 'Cascadia Code Nerd Font'.

## Oh My Posh Configuration

This setup downloads the pure theme locally to the same directory as your PowerShell profile (`pure.omp.json` alongside `Microsoft.PowerShell_profile.ps1`) for faster loading and offline availability. The theme is updated when you run `update.ps1`.
