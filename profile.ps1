# PowerShell 7 profile. Loaded from $PROFILE by install.ps1 (dot-source).

# Theme
# Local copy of the upstream amro theme, so the prompt works offline.
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$PSScriptRoot\themes\amro.omp.json" | Invoke-Expression
}

# Autocomplete
Import-Module PSReadLine
Set-PSReadLineOption -HistoryNoDuplicates
# Prediction fails when output is redirected (pwsh -Command, CI); ignore there.
try { Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView } catch {}
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Import-Module Microsoft.WinGet.CommandNotFound -ErrorAction SilentlyContinue

Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.Utf8Encoding]::new()
    winget complete --word="$wordToComplete" --commandline "$commandAst" --position $cursorPosition |
        ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}
if (Get-Command gh -ErrorAction SilentlyContinue) { gh completion -s powershell | Out-String | Invoke-Expression }
if (Get-Command uv -ErrorAction SilentlyContinue) { uv generate-shell-completion powershell | Out-String | Invoke-Expression }

# zoxide: z <dir>, zi (interactive)
if (Get-Command zoxide -ErrorAction SilentlyContinue) { zoxide init powershell | Out-String | Invoke-Expression }

# Aliases
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    function ls { eza --icons --group-directories-first @args }
    function ll { eza -la --icons --git --group-directories-first @args }
    function lt { eza --tree --level=2 --icons @args }
}
if (Get-Command bat -ErrorAction SilentlyContinue) {
    Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
    function cat { bat --paging=never @args }
}
Set-Alias lg lazygit
Set-Alias g git
function gs { git status -sb @args }
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function which($name) { (Get-Command $name).Source }
function touch($file) { if (-not (Test-Path $file)) { New-Item -ItemType File $file | Out-Null } }
