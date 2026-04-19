# ==========================================
# Linux-like PowerShell + fzf profile
# interactive use only
# ==========================================

# Measure startup time
$Global:ProfileLoadStart = [System.Diagnostics.Stopwatch]::StartNew()

# ---------- aliases ----------
Set-Alias vi nvim
Set-Alias vim nvim
Set-Alias py python
Set-Alias g git
Set-Alias c zoxide
Set-Alias z zoxide  # Quick directory jump with zoxide

function gc   { git clone @args }
function lg   { lazygit @args }

# ---------- env ----------
$env:BAT_THEME = 'TwoDark'
$env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
$env:FZF_CTRL_T_COMMAND  = $env:FZF_DEFAULT_COMMAND
$env:FZF_ALT_C_COMMAND   = 'fd --type d --hidden --follow --exclude .git'
$env:FZF_DEFAULT_OPTS    = '--height 80% --layout=reverse --border --inline-info'
$git = Get-Command git.exe -ErrorAction SilentlyContinue
if ($git) {
    $gitRoot = Split-Path (Split-Path $git.Source)
    $fileOne = Join-Path $gitRoot 'usr\bin\file.exe'
    if (Test-Path $fileOne) {
        $env:YAZI_FILE_ONE = $fileOne
    }
}

# ---------- modern ls ----------
function l   { la @args }
function ls  { eza --group-directories-first --icons=auto @args }
function ll  { eza -lh --group-directories-first --icons=auto @args }
function la  { eza -lah --group-directories-first --icons=auto @args }
function lt  { eza --tree --level=2 --icons=auto @args }
Remove-Item Alias:rm -Force -ErrorAction SilentlyContinue

function rm {
    Write-Host "rm 已保留为提醒。请改用: rip" -ForegroundColor Yellow
}

# ---------- cat / less ----------
function cat  { bat --paging=never --style=plain @args }
function ccat { bat --paging=never @args }

function less {
    if (Get-Command less.exe -ErrorAction SilentlyContinue) {
        & less.exe @args
    } else {
        Write-Host 'less 未安装，运行: scoop install less' -ForegroundColor Yellow
    }
}

# ---------- grep / find ----------
function grep { rg @args }
function find { fd @args }
function ff   { fd @args }

# ---------- helpers ----------
function which {
    param([Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)][string[]]$Name)
    foreach ($n in $Name) {
        Get-Command $n -ErrorAction SilentlyContinue |
            Select-Object Name, CommandType, Source
    }
}

function touch {
    param([Parameter(Mandatory=$true, ValueFromRemaining=$true)][string[]]$Path)
    foreach ($p in $Path) {
        if (Test-Path $p) {
            (Get-Item $p).LastWriteTime = Get-Date
        } else {
            New-Item -ItemType File -Path $p | Out-Null
        }
    }
}

function pwd { Get-Location }
function ..   { Set-Location .. }
function ...  { Set-Location ../.. }
function .... { Set-Location ../../.. }

function mkdir {
    param([Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)][string[]]$Path)
    foreach ($p in $Path) {
        New-Item -ItemType Directory -Path $p -Force | Out-Null
    }
}

function ln {
    param(
        [Parameter(Mandatory=$true)][string]$Target,
        [Parameter(Mandatory=$true)][string]$LinkName
    )
    New-Item -ItemType SymbolicLink -Path $LinkName -Target $Target
}

function __quote_path([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $Path }
    return "'" + ($Path -replace "'", "''") + "'"
}

# ---------- fzf helpers ----------
function __fzf_select_file {
    if (Get-Command bat -ErrorAction SilentlyContinue) {
        fd --type f --hidden --follow --exclude .git 2>$null |
            fzf --prompt 'Files> ' `
                --preview 'bat --color=always --style=numbers --line-range=:200 {}' `
                --preview-window 'right,60%,border-left'
    } else {
        fd --type f --hidden --follow --exclude .git 2>$null |
            fzf --prompt 'Files> '
    }
}

function __fzf_select_dir {
    fd --type d --hidden --follow --exclude .git 2>$null |
        fzf --prompt 'Dirs> '
}

function __fzf_select_history([string]$Query) {
    $historyPath = $null
    try { $historyPath = (Get-PSReadLineOption).HistorySavePath } catch {}
    if (-not $historyPath -or -not (Test-Path $historyPath)) { return }

    $lines = Get-Content $historyPath
    [array]::Reverse($lines)

    $seen = @{}
    $unique = foreach ($cmd in $lines) {
        if (-not [string]::IsNullOrWhiteSpace($cmd) -and -not $seen.ContainsKey($cmd)) {
            $seen[$cmd] = $true
            $cmd
        }
    }

    $unique | fzf --prompt 'History> ' --query $Query --tac --no-sort
}

# ---------- PSReadLine ----------
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue

    try {
        Set-PSReadLineOption -EditMode Emacs
        Set-PSReadLineOption -BellStyle None
        Set-PSReadLineOption -HistorySearchCursorMovesToEnd
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    } catch {}

    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow'  -Function BackwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Backspace' -Function BackwardDeleteWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Delete'    -Function DeleteWord

    Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -BriefDescription 'fzf history' -ScriptBlock {
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        $selected = __fzf_select_history $line
        if ($selected) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $selected)
        }
    }

    Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -BriefDescription 'fzf files' -ScriptBlock {
        $selected = __fzf_select_file
        if ($selected) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert((__quote_path $selected))
        }
    }

    Set-PSReadLineKeyHandler -Chord 'Alt+c' -BriefDescription 'fzf cd' -ScriptBlock {
        $selected = __fzf_select_dir
        if ($selected) {
            $target = __quote_path $selected
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("cd $target")
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        }
    }
}

# ---------- yazi ----------
function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8 -Raw
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath $cwd
    }
    Remove-Item -Path $tmp
}

# ---------- zellij ----------
function zellij-session {
    $sessions = zellij list-sessions 2>$null
    if ($sessions -match 'main') {
        zellij attach main
    } else {
        zellij attach -c main
    }
}

# Common aliases
Set-Alias zs zellij-session  # Quick zellij access
Set-Alias zj zellij           # Alternative zellij alias

# ---------- zoxide ----------
# 直接从 .shim 文件读取真实 exe 路径，避免 Scoop current junction
# 异常时 shim 挂起拖死整个 profile 的问题
$_zExe = $null
$_zShim = "$HOME\scoop\shims\zoxide.shim"
if (Test-Path $_zShim) {
    $_zPath = (Get-Content $_zShim | Where-Object { $_ -match '^path' }) -replace 'path\s*=\s*"?(.+?)"?\s*$', '$1'
    if ($_zPath -and (Test-Path $_zPath)) { $_zExe = $_zPath }
}
if ($_zExe) {
    Invoke-Expression (& $_zExe init powershell | Out-String)
}
Remove-Variable _zExe, _zShim, _zPath -ErrorAction SilentlyContinue

# ---------- pixi ----------
Register-ArgumentCompleter -CommandName pixi -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameter)
    # Lazy init on first use
    if (-not $Global:PixiCompletionLoaded) {
        $_pixiCmd = Get-Command pixi -ErrorAction SilentlyContinue
        if ($_pixiCmd) {
            try {
                Invoke-Expression (& $_pixiCmd.Source completion --shell powershell | Out-String)
                $Global:PixiCompletionLoaded = $true
            } catch {
                Write-Warning "Failed to load pixi completion: $_"
            }
        }
    }
}

# ---------- uv ----------
Register-ArgumentCompleter -CommandName uv -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameter)
    # Lazy init on first use
    if (-not $Global:UvCompletionLoaded) {
        $_uvCmd = Get-Command uv -ErrorAction SilentlyContinue
        if ($_uvCmd) {
            try {
                Invoke-Expression (& $_uvCmd.Source generate-shell-completion powershell | Out-String)
                $Global:UvCompletionLoaded = $true
            } catch {
                Write-Warning "Failed to load uv completion: $_"
            }
        }
    }
}

# ---------- startup checks ----------
$missingTools = @('zellij', 'bun', 'claude') | Where-Object {
    -not (Get-Command $_ -ErrorAction SilentlyContinue)
}
# Stop startup timer
$Global:ProfileLoadStart.Stop()
$Global:ProfileLoadTime = [math]::Round($Global:ProfileLoadStart.ElapsedMilliseconds, 0)

# Check for missing tools
$missingTools = @('zellij', 'bun', 'claude') | Where-Object {
    -not (Get-Command $_ -ErrorAction SilentlyContinue)
}

# ---------- startup display ----------
if ($Host.Name -eq 'ConsoleHost') {
    Write-Host "🚀 pwsh-config loaded ($($Global:ProfileLoadTime)ms)" -ForegroundColor Green
    Write-Host "Shortcuts: z(dir) | Ctrl+r history | Ctrl+t file | Alt+c cd" -ForegroundColor DarkGray

    # Git branch info
    $gitBranch = $null
    try {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $gitBranch = git rev-parse --abbrev-ref HEAD 2>$null
        }
    } catch {}

    if ($gitBranch) {
        Write-Host "📂 Git: $gitBranch branch" -ForegroundColor Magenta
    }

    # Zellij sessions info
    $zellijSessions = $null
    try {
        if (Get-Command zellij -ErrorAction SilentlyContinue) {
            $zellijSessions = zellij list-sessions 2>$null
        }
    } catch {}

    if ($zellijSessions) {
        $sessionCount = ($zellijSessions | Measure-Object).Count
        Write-Host "💡 $sessionCount active zellij session(s) - use 'zj' or 'zs'" -ForegroundColor Cyan
    }

    # Performance info
    if ($Global:ProfileLoadTime -lt 100) {
        Write-Host "⚡ Fast startup (<100ms)" -ForegroundColor Green
    }

    # Missing tools warning
    if ($missingTools) {
        Write-Host "⚠️  Missing tools: $($missingTools -join ', ')" -ForegroundColor Yellow
        Write-Host "   Run: .\scripts\bootstrap.ps1" -ForegroundColor DarkGray
    }
} else {
    Write-Host "pwsh-config loaded ($($Global:ProfileLoadTime)ms)" -ForegroundColor Yellow
}
