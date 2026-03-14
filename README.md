# pwsh-config
Personal PowerShell-centered terminal configuration for Windows.

## Structure
- `powershell/Microsoft.PowerShell_profile.ps1` - PowerShell profile
- `yazi/config/` - Yazi configuration, plugins, and flavors
- `scripts/bootstrap.ps1` - installs dependencies and links live paths to this repo

## Bootstrap
Run from PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
E:\github\pwsh-config\scripts\bootstrap.ps1
```

The bootstrap script installs the required Scoop packages, then links:

- `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`
- `%AppData%/yazi/config`

back to this repository.
