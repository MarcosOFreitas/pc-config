<#
.SYNOPSIS
  Installs apps from apps.json.
  Order per entry: "uv" (Python tools/interpreter) > "winget" > "choco" (fallback).
.EXAMPLE
  .\install.ps1                          # all categories (admin)
  .\install.ps1 -Categoria Dev,Terminal  # selected categories (admin)
  .\install.ps1 -Exportar                # list installed winget apps missing from apps.json
#>
param([string[]]$Categoria, [switch]$Exportar)
$ErrorActionPreference = 'Stop'

if ($Exportar) {
    $known = (Get-Content "$PSScriptRoot\apps.json" -Raw | ConvertFrom-Json).PSObject.Properties.Value.winget
    $tmp = Join-Path $env:TEMP 'winget-export.json'
    winget export -o $tmp --accept-source-agreements *> $null
    # Runtimes and frameworks come in as dependencies; not worth listing.
    $noise = '^(Microsoft\.(VCRedist|VCLibs|UI\.Xaml|WindowsAppRuntime|DotNet|AppInstaller|GameInput|WindowsSDK))'
    $missing = (Get-Content $tmp -Raw | ConvertFrom-Json).Sources.Packages.PackageIdentifier |
        Where-Object { $_ -notin $known -and $_ -notmatch $noise } | Sort-Object
    Remove-Item $tmp
    if ($missing) { Write-Host 'Instalados e fora do apps.json:' -ForegroundColor Yellow; $missing | ForEach-Object { "  $_" } }
    else { Write-Host 'apps.json cobre tudo que esta instalado.' -ForegroundColor Green }
    exit
}

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators')
if (-not $admin) { Write-Host 'x Rode como administrador.' -ForegroundColor Red; exit 1 }

function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Install-Choco {
    if (Get-Command choco -ErrorAction SilentlyContinue) { return }
    Write-Host '==> Instalando Chocolatey' -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Update-SessionPath
}

function Install-App($app) {
    $name = if ($app.nome) { $app.nome } elseif ($app.uv) { $app.uv } elseif ($app.winget) { $app.winget } else { $app.choco }

    if ($app.uv) {
        Update-SessionPath  # uv may have been installed earlier in this run
        if (-not (Get-Command uv -ErrorAction SilentlyContinue)) { Write-Host "  x $name (uv ausente)" -ForegroundColor Red; return $false }
        # "python" = interpreter; anything else = CLI tool in an isolated env.
        # TODO: drop --preview once `uv python install --default` is stable.
        if ($app.uv -eq 'python') { uv python install --default --preview } else { uv tool install $app.uv }
        if ($LASTEXITCODE -eq 0) { Write-Host "  + $name (uv)" -ForegroundColor Green; return $true }
    }
    if ($app.winget) {
        # Store IDs (9XXXXXXXXXXX) live in the msstore source.
        # TODO: msstore installs may fail without a Microsoft account signed in to the Store.
        $source = if ($app.winget -match '^9[A-Z0-9]{11}$') { 'msstore' } else { 'winget' }
        winget list --id $app.winget --exact --source $source --accept-source-agreements *> $null
        if ($LASTEXITCODE -eq 0) { Write-Host "  = $name (ja instalado)" -ForegroundColor DarkGray; return $true }
        winget install --id $app.winget --exact --source $source --silent `
            --accept-package-agreements --accept-source-agreements --disable-interactivity
        if ($LASTEXITCODE -eq 0) { Write-Host "  + $name (winget)" -ForegroundColor Green; return $true }
    }
    if ($app.choco) {
        Install-Choco
        choco install $app.choco -y --no-progress
        if ($LASTEXITCODE -in 0, 1641, 3010) { Write-Host "  + $name (choco)" -ForegroundColor Green; return $true }
    }
    Write-Host "  x $name falhou" -ForegroundColor Red
    return $false
}

$apps = Get-Content "$PSScriptRoot\apps.json" -Raw | ConvertFrom-Json
$failed = @()
foreach ($cat in $apps.PSObject.Properties) {
    if ($Categoria -and $cat.Name -notin $Categoria) { continue }
    Write-Host "==> $($cat.Name)" -ForegroundColor Cyan
    foreach ($app in $cat.Value) {
        if (-not (Install-App $app)) { $failed += @($app.nome, $app.uv, $app.winget, $app.choco) -ne $null | Select-Object -First 1 }
    }
}
Update-SessionPath

if ($failed) { Write-Host "`nFalharam: $($failed -join ', ')" -ForegroundColor Red; exit 1 }
Write-Host "`nApps instalados." -ForegroundColor Green
exit 0
