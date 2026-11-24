<#
.SYNOPSIS
  New-machine entry point. In an admin PowerShell:
    irm https://raw.githubusercontent.com/MarcosOFreitas/pc-config/main/bootstrap.ps1 | iex
  Downloads the repo to ~\pc-config, runs every setup script in order,
  then turns the folder into a git clone so it can be updated with `git pull`.

  With parameters (irm | iex cannot pass them):
    & ([scriptblock]::Create((irm <url>))) -Pular debloat
    & ([scriptblock]::Create((irm <url>))) -Passos install,vscode -Destino $HOME\dev\pc-config
  Or locally: .\bootstrap.ps1 -Passos install,git
.PARAMETER Passos
  Steps to run, in the fixed order below. Default: all.
.PARAMETER Pular
  Steps to skip.
.PARAMETER Destino
  Repo folder. Use the existing clone on an already configured PC to avoid a second copy.
#>
param(
    [ValidateSet('debloat', 'shell', 'install', 'wsl', 'vscode', 'git')]
    [string[]]$Passos = @('debloat', 'shell', 'install', 'wsl', 'vscode', 'git'),
    [ValidateSet('debloat', 'shell', 'install', 'wsl', 'vscode', 'git')]
    [string[]]$Pular = @(),
    [string]$Destino = "$HOME\pc-config"   # durable: $PROFILE dot-sources profile.ps1 from here
)
$ErrorActionPreference = 'Stop'
$repo = 'MarcosOFreitas/pc-config'
$dest = $Destino
# Fixed order; -Passos only filters it.
$steps = 'debloat', 'shell', 'install', 'wsl', 'vscode', 'git' | Where-Object { $_ -in $Passos -and $_ -notin $Pular }
if (-not $steps) { Write-Host 'x Nenhum passo selecionado.' -ForegroundColor Red; return }
Write-Host "Passos: $($steps -join ' > ')" -ForegroundColor Cyan

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators')
if (-not $admin) { Write-Host 'x Abra o PowerShell como administrador e rode de novo.' -ForegroundColor Red; return }

Set-ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072

if (Test-Path "$dest\.git") {
    Write-Host "==> $dest ja existe (git), usando como esta" -ForegroundColor Cyan
} else {
    Write-Host "==> Baixando $repo para $dest" -ForegroundColor Cyan
    $zip = Join-Path $env:TEMP 'pc-config.zip'
    $tmp = Join-Path $env:TEMP 'pc-config-extract'
    Invoke-WebRequest "https://github.com/$repo/archive/refs/heads/main.zip" -OutFile $zip -UseBasicParsing
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive $zip $tmp -Force
    New-Item -ItemType Directory -Force $dest | Out-Null
    Copy-Item "$tmp\pc-config-main\*" $dest -Recurse -Force
    Remove-Item $zip, $tmp -Recurse -Force
    Get-ChildItem $dest -Recurse -File | Unblock-File
}

# Each step is independent; a failure is reported and the next one still runs.
$failed = @()
foreach ($step in $steps) {
    Write-Host "`n########## $step.ps1 ##########" -ForegroundColor Magenta
    try {
        & "$dest\$step.ps1"
        if ($LASTEXITCODE) { throw "exit $LASTEXITCODE" }
    } catch {
        Write-Host "x $step.ps1: $_" -ForegroundColor Red
        $failed += $step
    }
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

if (-not (Test-Path "$dest\.git") -and (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "`n==> Ligando $dest ao GitHub" -ForegroundColor Cyan
    git -C $dest init -q -b main
    git -C $dest remote add origin "https://github.com/$repo.git"
    git -C $dest fetch -q origin
    git -C $dest reset -q origin/main
    git -C $dest branch -q -u origin/main
}

if ($failed) { Write-Host "`nFalharam: $($failed -join ', '). Rode de novo o script em $dest." -ForegroundColor Red }
Write-Host "`nPronto. Reinicie o PC." -ForegroundColor Green
