# Admin only needed without -SoPerfil (install.ps1 enforces it).
<#
.SYNOPSIS
  Installs PowerShell 7 + terminal tools (category "Terminal" of apps.json),
  links profile.ps1 into $PROFILE, installs the Nerd Font and points Windows Terminal at pwsh.
.EXAMPLE
  .\shell.ps1               # tools + profile
  .\shell.ps1 -SoPerfil     # profile only
#>
param([switch]$SoPerfil)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

if (-not $SoPerfil) { & "$root\install.ps1" -Categoria Terminal }

Write-Host '==> Perfil do PowerShell 7' -ForegroundColor Cyan
$target = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
if ((Test-Path $target) -and ((Get-Content $target -Raw) -like "*$root\profile.ps1*")) {
    Write-Host '  = perfil ja aponta para o repo' -ForegroundColor DarkGray
} else {
    if (Test-Path $target) { Copy-Item $target "$target.bak" -Force; Write-Host "  backup: $target.bak" }
    Set-Content $target ". '$root\profile.ps1'" -Encoding utf8
    Write-Host "  + $target" -ForegroundColor Green
}

Write-Host '==> Fonte Nerd Font' -ForegroundColor Cyan
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { oh-my-posh font install meslo }
else { Write-Host '  x oh-my-posh ausente' -ForegroundColor Red }

Write-Host '==> Windows Terminal: pwsh padrao + fonte' -ForegroundColor Cyan
$wt = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $wt) {
    try {
        # Runs on Windows PowerShell 5.1 too, so no -AsHashtable.
        # TODO: rewriting the file drops any comments the user had in settings.json.
        $cfg = Get-Content $wt -Raw | ConvertFrom-Json
        $cfg | Add-Member defaultProfile '{574e775e-4f2a-5b96-ac1e-a2962a402336}' -Force  # PowerShell 7 (fixed GUID)
        if (-not $cfg.profiles.defaults) { $cfg.profiles | Add-Member defaults ([pscustomobject]@{}) -Force }
        $cfg.profiles.defaults | Add-Member font ([pscustomobject]@{ face = 'MesloLGM Nerd Font' }) -Force
        Copy-Item $wt "$wt.bak" -Force
        [IO.File]::WriteAllText($wt, ($cfg | ConvertTo-Json -Depth 20))  # UTF-8 without BOM
        Write-Host '  + settings.json atualizado (backup .bak)' -ForegroundColor Green
    } catch { Write-Host "  x nao alterou settings.json: $_" -ForegroundColor Yellow }
} else { Write-Host '  Abra o Windows Terminal uma vez e rode .\shell.ps1 -SoPerfil' -ForegroundColor Yellow }

Write-Host '==> Windows Terminal como terminal padrao do Windows' -ForegroundColor Cyan
# Any console app (cmd, powershell, pwsh) opens inside Windows Terminal instead of conhost.
$console = 'HKCU:\Console\%%Startup'
if (-not (Test-Path $console)) { New-Item $console | Out-Null }
Set-ItemProperty $console DelegationConsole '{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}'
Set-ItemProperty $console DelegationTerminal '{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}'

Write-Host "`nPronto. Abra um novo pwsh." -ForegroundColor Green
exit 0
