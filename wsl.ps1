#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Installs WSL + Ubuntu and writes ~/.wslconfig limits (half of RAM and CPUs).
  Reboot may be needed on the first install.
#>
param([string]$Distro = 'Ubuntu')
# Not 'Stop': wsl.exe writes status text to stderr, which 5.1 would treat as fatal.
$ErrorActionPreference = 'Continue'

Write-Host '==> WSL' -ForegroundColor Cyan
wsl --update
$distros = (wsl --list --quiet) -replace "`0", ''   # wsl prints UTF-16
if ($distros -contains $Distro) {
    Write-Host "  = $Distro ja instalado" -ForegroundColor DarkGray
} else {
    wsl --install -d $Distro --no-launch
    Write-Host "  + $Distro (abra 'wsl' para criar o usuario)" -ForegroundColor Green
}

Write-Host '==> .wslconfig' -ForegroundColor Cyan
$cfg = "$HOME\.wslconfig"
if (Test-Path $cfg) {
    Write-Host "  = $cfg ja existe, nao alterado" -ForegroundColor DarkGray
} else {
    $ramGB = [math]::Floor((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB / 2)
    $cpus = [math]::Max(1, [math]::Floor([Environment]::ProcessorCount / 2))
    @"
[wsl2]
memory=${ramGB}GB
processors=$cpus
swap=4GB

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
"@ | Set-Content $cfg -Encoding ascii
    Write-Host "  + memory=${ramGB}GB processors=$cpus" -ForegroundColor Green
}

Write-Host "`nPronto. Rode 'wsl --shutdown' para aplicar o .wslconfig." -ForegroundColor Green
exit 0
