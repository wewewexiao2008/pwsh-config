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

Ensure-ScoopPackage -Name 'lazygit' -Bucket 'extras' -FallbackManifestUrl 'https://raw.githubusercontent.com/ScoopInstaller/Extras/master/bucket/lazygit.json' -InstalledAction $InstalledPackageAction

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
