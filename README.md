# pwsh-config
Personal PowerShell-centered terminal configuration for Windows.

## Structure
- `powershell/Microsoft.PowerShell_profile.ps1` - PowerShell profile
- `yazi/config/` - Yazi configuration, plugins, and flavors
- `scripts/bootstrap.ps1` - installs dependencies and links live paths to this repo

## Bootstrap

Install Scoop (requires non-admin):

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

Run from PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
# in this directory
.\scripts\bootstrap.ps1
```

The bootstrap script installs the required Scoop packages, then links:

- `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`
- `%AppData%/yazi/config`

back to this repository.

If a package is already installed, bootstrap can:
- prompt you per package (default): `-InstalledPackageAction Prompt`
- force update all installed packages: `-InstalledPackageAction Update`
- force reinstall all installed packages: `-InstalledPackageAction Reinstall`

Examples:
```powershell
E:\github\pwsh-config\scripts\bootstrap.ps1 -InstalledPackageAction Prompt
E:\github\pwsh-config\scripts\bootstrap.ps1 -InstalledPackageAction Update
E:\github\pwsh-config\scripts\bootstrap.ps1 -InstalledPackageAction Reinstall
```

## Tools

<table>
  <thead>
    <tr>
      <th align="left">Tool</th>
      <th align="left">Purpose</th>
      <th align="left">Link</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td colspan="3" align="center"><strong>Shell / Navigation</strong></td>
    </tr>
    <tr>
      <td>zoxide</td>
      <td>Smarter <code>cd</code>, provides <code>z</code> and <code>zi</code>.</td>
      <td><a href="https://github.com/ajeetdsouza/zoxide">GitHub</a></td>
    </tr>
    <tr>
      <td>pixi</td>
      <td>Cross-platform package/workflow manager; PowerShell completion is loaded from profile.</td>
      <td><a href="https://github.com/prefix-dev/pixi">GitHub</a></td>
    </tr>
    <tr>
      <td>fzf</td>
      <td>Fuzzy finder for history, file insert, and directory jump.</td>
      <td><a href="https://github.com/junegunn/fzf">GitHub</a></td>
    </tr>
    <tr>
      <td>eza</td>
      <td>Modern <code>ls</code> replacement used by <code>l</code>, <code>ls</code>, <code>ll</code>, <code>la</code>, and <code>lt</code>.</td>
      <td><a href="https://github.com/eza-community/eza">GitHub</a></td>
    </tr>
    <tr>
      <td>PSReadLine</td>
      <td>Improved line editing, history search, and inline predictions for PowerShell.</td>
      <td><a href="https://github.com/PowerShell/PSReadLine">GitHub</a></td>
    </tr>
    <tr>
      <td colspan="3" align="center"><strong>Development Toolchains</strong></td>
    </tr>
    <tr>
      <td>rust</td>
      <td>Rust toolchain via <code>rustup</code>; provides <code>cargo</code>, <code>rustc</code>, and <code>rustup</code>.</td>
      <td><a href="https://rustup.rs/">rustup.rs</a></td>
    </tr>
    <tr>
      <td>uv</td>
      <td>Fast Python package manager and resolver.</td>
      <td><a href="https://github.com/astral-sh/uv">GitHub</a></td>
    </tr>
    <tr>
      <td>VS Build Tools 2022</td>
      <td>C++ build tools via <code>winget</code>; provides MSVC, Windows SDK, and CMake.</td>
      <td><a href="https://visualstudio.microsoft.com/visual-cpp-build-tools/">Microsoft</a></td>
    </tr>
    <tr>
      <td colspan="3" align="center"><strong>File Manager / UI</strong></td>
    </tr>
    <tr>
      <td>yazi</td>
      <td>Terminal file manager launched with <code>y</code>.</td>
      <td><a href="https://github.com/sxyazi/yazi">GitHub</a></td>
    </tr>
    <tr>
      <td>smart-enter.yazi</td>
      <td>Makes <code>l</code> open files or enter directories in Yazi.</td>
      <td><a href="https://github.com/yazi-rs/plugins/tree/main/smart-enter.yazi">GitHub</a></td>
    </tr>
    <tr>
      <td>toggle-pane.yazi</td>
      <td>Makes <code>T</code> maximize or restore the Yazi preview pane.</td>
      <td><a href="https://github.com/yazi-rs/plugins/tree/main/toggle-pane.yazi">GitHub</a></td>
    </tr>
    <tr>
      <td>full-border.yazi</td>
      <td>Adds rounded full borders to the Yazi UI.</td>
      <td><a href="https://github.com/yazi-rs/plugins/tree/main/full-border.yazi">GitHub</a></td>
    </tr>
    <tr>
      <td>git.yazi</td>
      <td>Shows Git status inline inside Yazi.</td>
      <td><a href="https://github.com/yazi-rs/plugins/tree/main/git.yazi">GitHub</a></td>
    </tr>
    <tr>
      <td>catppuccin-mocha.yazi</td>
      <td>Dark Catppuccin flavor for Yazi.</td>
      <td><a href="https://github.com/yazi-rs/flavors/tree/main/catppuccin-mocha.yazi">GitHub</a></td>
    </tr>
    <tr>
      <td colspan="3" align="center"><strong>Search / View</strong></td>
    </tr>
    <tr>
      <td>bat</td>
      <td>Better <code>cat</code> with syntax highlighting, also used in previews.</td>
      <td><a href="https://github.com/sharkdp/bat">GitHub</a></td>
    </tr>
    <tr>
      <td>less</td>
      <td>Pager.</td>
      <td><a href="https://github.com/gwsw/less">GitHub</a></td>
    </tr>
    <tr>
      <td>ripgrep</td>
      <td>Fast recursive text search, used as <code>grep</code>.</td>
      <td><a href="https://github.com/BurntSushi/ripgrep">GitHub</a></td>
    </tr>
    <tr>
      <td>fd</td>
      <td>Fast file search, used as <code>find</code> and <code>ff</code>.</td>
      <td><a href="https://github.com/sharkdp/fd">GitHub</a></td>
    </tr>
    <tr>
      <td>jq</td>
      <td>JSON preview and processing.</td>
      <td><a href="https://github.com/jqlang/jq">GitHub</a></td>
    </tr>
    <tr>
      <td colspan="3" align="center"><strong>Safe Delete / Git / Editor</strong></td>
    </tr>
    <tr>
      <td>rip2</td>
      <td>Safe delete tool used as <code>rip</code>; <code>rm</code> only shows a reminder.</td>
      <td><a href="https://github.com/MilesCranmer/rip2">GitHub</a></td>
    </tr>
    <tr>
      <td>lazygit</td>
      <td>Terminal UI for Git.</td>
      <td><a href="https://github.com/jesseduffield/lazygit">GitHub</a></td>
    </tr>
    <tr>
      <td>Git for Windows</td>
      <td>Git client; also provides <code>file.exe</code> for Yazi MIME detection.</td>
      <td><a href="https://github.com/git-for-windows/git">GitHub</a></td>
    </tr>
    <tr>
      <td>Neovim</td>
      <td>Editor, used as <code>vi</code> and <code>vim</code>.</td>
      <td><a href="https://github.com/neovim/neovim">GitHub</a></td>
    </tr>
    <tr>
      <td colspan="3" align="center"><strong>Yazi Preview Dependencies</strong></td>
    </tr>
    <tr>
      <td>ffmpeg</td>
      <td>Video preview support for Yazi.</td>
      <td><a href="https://github.com/FFmpeg/FFmpeg">GitHub</a></td>
    </tr>
    <tr>
      <td>7-Zip</td>
      <td>Archive preview and extraction support for Yazi.</td>
      <td><a href="https://www.7-zip.org/">Website</a></td>
    </tr>
    <tr>
      <td>poppler</td>
      <td>PDF preview support for Yazi.</td>
      <td><a href="https://gitlab.freedesktop.org/poppler/poppler">Project</a></td>
    </tr>
    <tr>
      <td>resvg</td>
      <td>SVG preview support for Yazi.</td>
      <td><a href="https://github.com/RazrFalcon/resvg">GitHub</a></td>
    </tr>
    <tr>
      <td>ImageMagick</td>
      <td>Extra image and font preview support for Yazi.</td>
      <td><a href="https://github.com/ImageMagick/ImageMagick">GitHub</a></td>
    </tr>
  </tbody>
</table>

## Shortcuts

<table>
  <thead>
    <tr>
      <th align="left">Scope</th>
      <th align="left">Shortcut</th>
      <th align="left">Action</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Shell</td>
      <td><code>Ctrl+r</code></td>
      <td>fzf history search</td>
    </tr>
    <tr>
      <td>Shell</td>
      <td><code>Ctrl+t</code></td>
      <td>fzf file insert</td>
    </tr>
    <tr>
      <td>Shell</td>
      <td><code>Alt+c</code></td>
      <td>fzf directory jump</td>
    </tr>
    <tr>
      <td>Shell</td>
      <td><code>Ctrl+LeftArrow</code></td>
      <td>Move backward by word</td>
    </tr>
    <tr>
      <td>Shell</td>
      <td><code>Ctrl+RightArrow</code></td>
      <td>Move forward by word</td>
    </tr>
    <tr>
      <td>Shell</td>
      <td><code>Ctrl+Backspace</code></td>
      <td>Delete previous word</td>
    </tr>
    <tr>
      <td>Shell</td>
      <td><code>Ctrl+Delete</code></td>
      <td>Delete next word</td>
    </tr>
    <tr>
      <td>Yazi</td>
      <td><code>l</code></td>
      <td>Open file / enter directory (smart-enter)</td>
    </tr>
    <tr>
      <td>Yazi</td>
      <td><code>T</code></td>
      <td>Toggle preview pane maximize/restore</td>
    </tr>
  </tbody>
</table>

## Aliases

<table>
  <thead>
    <tr>
      <th align="left">Type</th>
      <th align="left">Name</th>
      <th align="left">Expands to</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Alias</td><td><code>vi</code></td><td><code>nvim</code></td></tr>
    <tr><td>Alias</td><td><code>vim</code></td><td><code>nvim</code></td></tr>
    <tr><td>Alias</td><td><code>py</code></td><td><code>python</code></td></tr>
    <tr><td>Alias</td><td><code>g</code></td><td><code>git</code></td></tr>
    <tr><td>Alias</td><td><code>c</code></td><td><code>zoxide</code></td></tr>
    <tr><td>Function</td><td><code>l</code></td><td><code>la</code></td></tr>
    <tr><td>Function</td><td><code>ls</code></td><td><code>eza --group-directories-first --icons=auto</code></td></tr>
    <tr><td>Function</td><td><code>ll</code></td><td><code>eza -lh --group-directories-first --icons=auto</code></td></tr>
    <tr><td>Function</td><td><code>la</code></td><td><code>eza -lah --group-directories-first --icons=auto</code></td></tr>
    <tr><td>Function</td><td><code>lt</code></td><td><code>eza --tree --level=2 --icons=auto</code></td></tr>
    <tr><td>Function</td><td><code>cat</code></td><td><code>bat --paging=never --style=plain</code></td></tr>
    <tr><td>Function</td><td><code>ccat</code></td><td><code>bat --paging=never</code></td></tr>
    <tr><td>Function</td><td><code>grep</code></td><td><code>rg</code></td></tr>
    <tr><td>Function</td><td><code>find</code></td><td><code>fd</code></td></tr>
    <tr><td>Function</td><td><code>ff</code></td><td><code>fd</code></td></tr>
    <tr><td>Function</td><td><code>y</code></td><td><code>yazi ... --cwd-file=...</code></td></tr>
    <tr><td>Function</td><td><code>rm</code></td><td>Reminder to use <code>rip</code></td></tr>
  </tbody>
</table>
