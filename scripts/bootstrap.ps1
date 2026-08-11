param(
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent),
    [ValidateSet('Prompt', 'Update', 'Reinstall')]
    [string]$InstalledPackageAction = 'Prompt',
    [switch]$InstallDevelopmentToolchain
)

$ErrorActionPreference = 'Stop'

function Ensure-ScoopInstalled {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        throw 'Scoop is not installed or not available in PATH.'
    }
}
function Get-ScoopConfigPath {
    return Join-Path $HOME '.config\scoop\config.json'
}

function Get-ScoopConfigValue {
    param([Parameter(Mandatory = $true)][string]$Name)

    $configPath = Get-ScoopConfigPath
    if (-not (Test-Path -LiteralPath $configPath)) {
        return $null
    }

    $raw = Get-Content -LiteralPath $configPath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }

    $config = $raw | ConvertFrom-Json
    return $config.$Name
}

function Install-ScoopManifestWithoutJunction {
    param([Parameter(Mandatory = $true)][string]$ManifestUrl)

    $configName = 'no_junction'
    $previousValue = Get-ScoopConfigValue -Name $configName
    $hadPreviousValue = $null -ne $previousValue

    if (-not $hadPreviousValue -or -not [bool]$previousValue) {
        scoop config $configName true | Out-Null
    }

    try {
        scoop install $ManifestUrl
    } finally {
        if (-not $hadPreviousValue) {
            scoop config rm $configName | Out-Null
        } elseif (-not [bool]$previousValue) {
            scoop config $configName $previousValue | Out-Null
        }
    }
}

function Ensure-ScoopPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Bucket,
        [string]$FallbackManifestUrl,
        [ValidateSet('Prompt', 'Update', 'Reinstall')]
        [string]$InstalledAction = 'Prompt'
    )
    $installed = scoop list | Select-String -Pattern ("(?m)^" + [regex]::Escape($Name) + "\s")
    if (-not $installed) {
        $bucketReady = $true
        if ($Bucket) {
            $bucketInstalled = scoop bucket list | Select-String -Pattern ("(?m)^" + [regex]::Escape($Bucket) + "\s")
            if (-not $bucketInstalled) {
                try {
                    scoop bucket add $Bucket
                } catch {
                    if (-not $FallbackManifestUrl) {
                        throw
                    }

                    Write-Warning "Unable to add Scoop bucket '$Bucket'. Falling back to manifest URL for '$Name'."
                    $bucketReady = $false
                }
            }
        }

        if ($bucketReady) {
            try {
                scoop install $Name
                return
            } catch {
                if (-not $FallbackManifestUrl) {
                    throw
                }

                Write-Warning "Unable to install '$Name' from Scoop bucket metadata. Falling back to manifest URL."
            }
        }

        Install-ScoopManifestWithoutJunction -ManifestUrl $FallbackManifestUrl
        return
    }

    $action = $InstalledAction
    if ($InstalledAction -eq 'Prompt') {
        $choice = Read-Host "Package '$Name' is already installed. Choose [U]pdate or [R]einstall (default: U)"
        if ($choice -match '^(r|reinstall)$') {
            $action = 'Reinstall'
        } else {
            $action = 'Update'
        }
    }

    if ($action -eq 'Reinstall') {
        scoop uninstall $Name
        try {
            scoop install $Name
        } catch {
            if (-not $FallbackManifestUrl) {
                throw
            }

            Write-Warning "Unable to reinstall '$Name' from Scoop bucket metadata. Falling back to manifest URL."
            Install-ScoopManifestWithoutJunction -ManifestUrl $FallbackManifestUrl
        }
        return
    }
    try {
        scoop update $Name
    } catch {
        if (-not $FallbackManifestUrl) {
            throw
        }

        Write-Warning "Unable to update '$Name' from Scoop bucket metadata. Reinstalling from manifest URL."
        scoop uninstall $Name
        Install-ScoopManifestWithoutJunction -ManifestUrl $FallbackManifestUrl
    }
}

function Remove-ExistingPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Force -Recurse
    }
}

function New-DirectoryLink {
    param(
        [Parameter(Mandatory = $true)][string]$LinkPath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    Remove-ExistingPath $LinkPath
    try {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath | Out-Null
    } catch {
        New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath | Out-Null
    }
}

function New-ProfileLink {
    param(
        [Parameter(Mandatory = $true)][string]$LinkPath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    Remove-ExistingPath $LinkPath
    try {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath | Out-Null
    } catch {
        $escaped = $TargetPath.Replace("'", "''")
        Set-Content -Path $LinkPath -Encoding utf8 -Value ". '$escaped'"
    }
}

function New-WezTermConfigLink {
    param(
        [Parameter(Mandatory = $true)][string]$LinkPath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    Remove-ExistingPath $LinkPath
    try {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath | Out-Null
    } catch {
        $escaped = $TargetPath.Replace('\', '/').Replace("'", "\'")
        $loader = @(
            "local wezterm = require 'wezterm'"
            "local config_path = '$escaped'"
            ''
            'wezterm.add_to_config_reload_watch_list(config_path)'
            ''
            'return dofile(config_path)'
        )
        Set-Content -Path $LinkPath -Encoding utf8 -Value $loader
    }
}

function New-ZellijConfigLink {
    param(
        [Parameter(Mandatory = $true)][string]$LinkPath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    Remove-ExistingPath $LinkPath
    try {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath | Out-Null
    } catch {
        # For zellij config, copy the actual content instead of sourcing
        Copy-Item -Path $TargetPath -Destination $LinkPath -Force
    }
}

Ensure-ScoopInstalled

$mainPackages = @(
    'bat',
    'bun',
    'eza',
    'fd',
    'ffmpeg',
    'fzf',
    'imagemagick',
    'jq',
    'less',
    'neovim',
    'pixi',
    'poppler',
    'resvg',
    'rip',
    'ripgrep',
    'yazi',
    'uv',
    'zellij',
    'zoxide',
    '7zip'
)

# Get all installed packages at once for batch processing
$installedOutput = scoop list 2>$null
$installedSet = @{}
if ($installedOutput) {
    $installedOutput | ForEach-Object {
        if ($_ -match '^(\S+)') {
            $installedSet[$matches[1]] = $true
        }
    }
}

# Separate packages by installation status
$notInstalled = $mainPackages | Where-Object { -not $installedSet.ContainsKey($_) }
$alreadyInstalled = $mainPackages | Where-Object { $installedSet.ContainsKey($_) }

# Batch install uninstalled packages
if ($notInstalled.Count -gt 0) {
    Write-Host "Installing $($notInstalled.Count) packages: $($notInstalled -join ', ')" -ForegroundColor Cyan
    scoop install @notInstalled
}

# Handle already installed packages based on action
if ($alreadyInstalled.Count -gt 0) {
    if ($InstalledPackageAction -eq 'Update') {
        Write-Host "Updating $($alreadyInstalled.Count) packages" -ForegroundColor Cyan
        scoop update @alreadyInstalled
    } elseif ($InstalledPackageAction -eq 'Reinstall') {
        foreach ($pkg in $alreadyInstalled) {
            $choice = Read-Host "Reinstall '$pkg'? [Y/n]"
            if ($choice -notmatch '^n') {
                scoop uninstall $pkg
                scoop install $pkg
            }
        }
    } else {
        Write-Host "Packages already installed. Use -Update or -Reinstall to update them." -ForegroundColor Yellow
    }
}

# Handle lazygit separately (from extras bucket)
Ensure-ScoopPackage -Name 'lazygit' -Bucket 'extras' -FallbackManifestUrl 'https://raw.githubusercontent.com/ScoopInstaller/Extras/master/bucket/lazygit.json' -InstalledAction $InstalledPackageAction

# ---------- Fonts ----------
$fontPackages = @(
    'JetBrainsMono-NF-CN',
    'Maple-Mono-NF-CN'
)

$nerdFontsBucket = scoop bucket list | Select-String -Pattern '(?m)^nerd-fonts\s'
if (-not $nerdFontsBucket) {
    Write-Host "Adding nerd-fonts bucket..." -ForegroundColor Cyan
    scoop bucket add nerd-fonts
}

$installedFonts = @{}
scoop list 2>$null | ForEach-Object { if ($_ -match '^(\S+)') { $installedFonts[$matches[1]] = $true } }

$fontsToInstall = $fontPackages | Where-Object { -not $installedFonts.ContainsKey($_) }
$fontsInstalled = $fontPackages | Where-Object { $installedFonts.ContainsKey($_) }

if ($fontsToInstall.Count -gt 0) {
    Write-Host "Installing fonts: $($fontsToInstall -join ', ')" -ForegroundColor Cyan
    scoop install @fontsToInstall
}
if ($fontsInstalled.Count -gt 0) {
    if ($InstalledPackageAction -eq 'Update') {
        scoop update @fontsInstalled
    } elseif ($InstalledPackageAction -eq 'Reinstall') {
        scoop uninstall @fontsInstalled
        scoop install @fontsInstalled
    } else {
        Write-Host "Fonts already installed: $($fontsInstalled -join ', ')" -ForegroundColor Yellow
    }
}

# Install Bun tools (opencode-ai, qodercli, codex)
if (Get-Command bun -ErrorAction SilentlyContinue) {
    Write-Host "Installing Bun tools: opencode-ai, qodercli, codex" -ForegroundColor Cyan
    try {
        bun add -g opencode-ai
        # Use npm for qodercli due to Windows compatibility issues
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            try {
                npm install -g @qoder-ai/qodercli
            } catch {
                Write-Warning "qodercli installation via npm failed. Skipping."
            }
        }
        bun add -g @openai/codex
    } catch {
        Write-Warning "Failed to install Bun tools: $_"
    }
} else {
    Write-Warning "Bun not found. Skipping opencode-ai, qodercli and codex installation."
}

# Install/update Claude Code (official WinGet package)
Write-Host "Installing/updating Claude Code..." -ForegroundColor Cyan
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warning 'winget not found. Skipping Claude Code installation.'
} else {
    $claudeInstalled = winget list --id Anthropic.ClaudeCode -e --source winget 2>$null | Select-String -Pattern 'Anthropic\.ClaudeCode'
    if ($claudeInstalled) {
        winget upgrade --id Anthropic.ClaudeCode -e --accept-source-agreements --accept-package-agreements
    } else {
        winget install --id Anthropic.ClaudeCode -e --accept-source-agreements --accept-package-agreements
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Claude Code installation exited with code $LASTEXITCODE."
    }
}

# ---------- Rust (via rustup) ----------
function Ensure-Rustup {
    if (Get-Command cargo -ErrorAction SilentlyContinue) {
        Write-Host "Rust toolchain already installed ($(cargo --version))." -ForegroundColor DarkGray
        return
    }

    Write-Host 'Installing Rust toolchain via rustup...' -ForegroundColor Cyan
    $installer = Join-Path $env:TEMP 'rustup-init.exe'
    Invoke-WebRequest -Uri 'https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe' -OutFile $installer -UseBasicParsing
    & $installer -y --default-toolchain stable
    Remove-Item $installer -Force -ErrorAction SilentlyContinue

    # Add cargo bin to current session PATH so subsequent steps can find it
    $cargobin = Join-Path $HOME '.cargo\bin'
    if (Test-Path $cargobin) {
        $env:PATH = "$cargobin;$env:PATH"
    }
}

# ---------- Visual Studio Build Tools (via vs_BuildTools.exe) ----------
function Ensure-VsBuildTools {
    $installerDir = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer'
    $vsWhere = Join-Path $installerDir 'vswhere.exe'

    if ((Test-Path $vsWhere) -and (& $vsWhere -products Microsoft.VisualStudio.Product.BuildTools -requires Microsoft.VisualStudio.Workload.VCTools -property installationPath)) {
        Write-Host 'Visual Studio Build Tools (C++) already installed.' -ForegroundColor DarkGray
        return
    }

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host 'VS Build Tools requires admin. Elevating...' -ForegroundColor Cyan
        $scriptBlock = @'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$installer = Join-Path $env:TEMP 'vs_BuildTools.exe'
(New-Object Net.WebClient).DownloadFile('https://aka.ms/vs/17/release/vs_BuildTools.exe', $installer)
& $installer --quiet --wait --norestart --force --includeRecommended `
    --add Microsoft.VisualStudio.Workload.VCTools `
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    --add Microsoft.VisualStudio.Component.Windows11SDK.26100 `
    --add Microsoft.VisualStudio.Component.VC.CMake.Project
Remove-Item $installer -Force -ErrorAction SilentlyContinue
'@
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($scriptBlock))
        $proc = Start-Process powershell.exe -Verb RunAs -Wait -PassThru -ArgumentList "-NoProfile -EncodedCommand $encoded"
        if ($proc.ExitCode -ne 0 -and $proc.ExitCode -ne 3010) {
            Write-Warning "VS Build Tools installation exited with code $($proc.ExitCode)."
        }
        return
    }

    Write-Host 'Installing Visual Studio Build Tools 2022 (C++ workload)...' -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $installer = Join-Path $env:TEMP 'vs_BuildTools.exe'
    (New-Object Net.WebClient).DownloadFile('https://aka.ms/vs/17/release/vs_BuildTools.exe', $installer)
    & $installer --quiet --wait --norestart --force --includeRecommended `
        --add Microsoft.VisualStudio.Workload.VCTools `
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        --add Microsoft.VisualStudio.Component.Windows11SDK.26100 `
        --add Microsoft.VisualStudio.Component.VC.CMake.Project
    Remove-Item $installer -Force -ErrorAction SilentlyContinue
}

if ($InstallDevelopmentToolchain) {
    Ensure-Rustup
    Ensure-VsBuildTools
} else {
    Write-Host 'Skipping optional Rust and Visual Studio Build Tools. Use -InstallDevelopmentToolchain to install them.' -ForegroundColor DarkGray
}

$profileSource = Join-Path $RepoRoot 'powershell\Microsoft.PowerShell_profile.ps1'
$weztermSource = Join-Path $RepoRoot 'wezterm\wezterm.lua'
$nvimSource = Join-Path $RepoRoot 'nvim'
$yaziSource = Join-Path $RepoRoot 'yazi\config'
$zellijSource = Join-Path $RepoRoot 'zellij\config.kdl'

$profileTarget5 = Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
$profileTarget7 = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$weztermTarget = Join-Path $HOME '.wezterm.lua'
$nvimTarget = Join-Path $env:LOCALAPPDATA 'nvim'
$yaziTarget = Join-Path $env:APPDATA 'yazi\config'
$zellijTarget = Join-Path $env:APPDATA 'Zellij\config\config.kdl'

New-Item -ItemType Directory -Force -Path (Split-Path $profileTarget5 -Parent) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $profileTarget7 -Parent) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $yaziTarget -Parent) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $zellijTarget -Parent) | Out-Null

New-ProfileLink -LinkPath $profileTarget5 -TargetPath $profileSource
New-ProfileLink -LinkPath $profileTarget7 -TargetPath $profileSource
New-WezTermConfigLink -LinkPath $weztermTarget -TargetPath $weztermSource
New-DirectoryLink -LinkPath $nvimTarget -TargetPath $nvimSource
New-DirectoryLink -LinkPath $yaziTarget -TargetPath $yaziSource
New-ZellijConfigLink -LinkPath $zellijTarget -TargetPath $zellijSource

Write-Host 'pwsh-config bootstrap complete.' -ForegroundColor Green
Write-Host 'Restart PowerShell to load the migrated profile.' -ForegroundColor DarkGray
