<#
.SYNOPSIS
  Installs VS Code extensions from vscode\extensions.txt and copies
  vscode\settings.json + keybindings.json to the user folder (old files backed up as .bak).
.EXAMPLE
  .\vscode.ps1            # extensions + settings
  .\vscode.ps1 -Exportar  # save current machine's extensions/settings back into the repo
#>
param([switch]$Exportar)
$ErrorActionPreference = 'Stop'
$repo = "$PSScriptRoot\vscode"
$user = "$env:APPDATA\Code\User"

if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    Write-Host 'x VS Code nao encontrado. Rode .\install.ps1 -Categoria Dev antes.' -ForegroundColor Red
    exit 1
}

if ($Exportar) {
    code --list-extensions | Set-Content "$repo\extensions.txt"
    Copy-Item "$user\settings.json", "$user\keybindings.json" $repo -ErrorAction SilentlyContinue
    Write-Host 'Exportado para vscode\. Revise o diff antes do commit (settings podem ter tokens).' -ForegroundColor Yellow
    exit
}

# TODO: extensions removed from extensions.txt are not uninstalled; remove them by hand.
Write-Host '==> Extensoes' -ForegroundColor Cyan
$installed = code --list-extensions
$failed = @()
foreach ($ext in Get-Content "$repo\extensions.txt" | Where-Object { $_.Trim() }) {
    if ($ext -in $installed) { Write-Host "  = $ext" -ForegroundColor DarkGray; continue }
    code --install-extension $ext --force *> $null
    if ($LASTEXITCODE -eq 0) { Write-Host "  + $ext" -ForegroundColor Green } else { Write-Host "  x $ext" -ForegroundColor Red; $failed += $ext }
}

Write-Host '==> Configuracoes' -ForegroundColor Cyan
New-Item -ItemType Directory -Force $user | Out-Null
foreach ($file in 'settings.json', 'keybindings.json') {
    $dest = "$user\$file"
    if (Test-Path $dest) { Copy-Item $dest "$dest.bak" -Force }
    Copy-Item "$repo\$file" $dest -Force
    Write-Host "  + $file" -ForegroundColor Green
}

if ($failed) { Write-Host "`nFalharam: $($failed -join ', ')" -ForegroundColor Red; exit 1 }
Write-Host "`nPronto. Reabra o VS Code." -ForegroundColor Green
exit 0
