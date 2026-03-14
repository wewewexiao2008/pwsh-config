param(
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent),
    [ValidateSet('Prompt', 'Update', 'Reinstall')]
    [string]$InstalledPackageAction = 'Prompt'
)

$ErrorActionPreference = 'Stop'

function Ensure-ScoopInstalled {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        throw 'Scoop is not installed or not available in PATH.'
    }
}

function Ensure-ScoopPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Bucket,
        [ValidateSet('Prompt', 'Update', 'Reinstall')]
        [string]$InstalledAction = 'Prompt'
    )

    if ($Bucket) {
        $bucketInstalled = scoop bucket list | Select-String -Pattern ("(?m)^" + [regex]::Escape($Bucket) + "\s")
        if (-not $bucketInstalled) {
            scoop bucket add $Bucket
        }
    }
    $installed = scoop list | Select-String -Pattern ("(?m)^" + [regex]::Escape($Name) + "\s")
    if (-not $installed) {
        scoop install $Name
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
        scoop install $Name
        return
    }

    scoop update $Name
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

Ensure-ScoopInstalled

$mainPackages = @(
    'bat',
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
    'zoxide',
    '7zip'
)

foreach ($pkg in $mainPackages) {
    Ensure-ScoopPackage -Name $pkg -InstalledAction $InstalledPackageAction
}

Ensure-ScoopPackage -Name 'lazygit' -Bucket 'extras' -InstalledAction $InstalledPackageAction

$profileSource = Join-Path $RepoRoot 'powershell\Microsoft.PowerShell_profile.ps1'
$yaziSource = Join-Path $RepoRoot 'yazi\config'

$profileTarget = Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
$yaziTarget = Join-Path $env:APPDATA 'yazi\config'

New-Item -ItemType Directory -Force -Path (Split-Path $profileTarget -Parent) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $yaziTarget -Parent) | Out-Null

New-ProfileLink -LinkPath $profileTarget -TargetPath $profileSource
New-DirectoryLink -LinkPath $yaziTarget -TargetPath $yaziSource

Write-Host 'pwsh-config bootstrap complete.' -ForegroundColor Green
Write-Host 'Restart PowerShell to load the migrated profile.' -ForegroundColor DarkGray
