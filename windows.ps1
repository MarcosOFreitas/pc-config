#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Windows preferences: dark mode, taskbar, Start menu, region, files, power.
  debloat.ps1 removes things; this one only sets preferences.
  Values Windows locks (UCPD) only warn. Run again after changing your mind: it is idempotent.
#>
. "$PSScriptRoot\lib.ps1"
$ErrorActionPreference = 'Continue'
$cv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion'

Write-Host '==> Aparencia' -ForegroundColor Cyan
Set-Reg "$cv\Themes\Personalize" AppsUseLightTheme 0
Set-Reg "$cv\Themes\Personalize" SystemUsesLightTheme 0

Write-Host '==> Barra de tarefas' -ForegroundColor Cyan
Set-Reg "$cv\Explorer\Advanced" TaskbarAl 1                 # icons centered
Set-Reg "$cv\Search" SearchboxTaskbarMode 0                 # no search box
Set-Reg "$cv\Explorer\Advanced" ShowTaskViewButton 0
# Auto-hide is left to the Windhawk mod mac-island-dock (hiding.hideWhen = mouseAway): it turns
# Windows' auto-hide on and off by itself, and a permanent registry value would fight it.

Write-Host '==> Menu Iniciar' -ForegroundColor Cyan
Set-Reg "$cv\Explorer\Advanced" Start_TrackDocs 0
Set-Reg "$cv\Explorer\Advanced" Start_TrackProgs 0
Set-Reg "$cv\Explorer\Advanced" Start_IrisRecommendations 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' HideRecommendedSection 1   # Education/Enterprise only

Write-Host '==> Regiao, hora e teclado' -ForegroundColor Cyan
try {
    Set-TimeZone -Id 'E. South America Standard Time'
    Set-Service w32time -StartupType Automatic
    Start-Service w32time -ErrorAction SilentlyContinue
    w32tm /resync 2>&1 | Out-Null
    if ((Get-WinUserLanguageList)[0].LanguageTag -ne 'pt-BR') {
        Set-WinUserLanguageList (New-WinUserLanguageList pt-BR) -Force   # includes the ABNT2 layout
    }
    Set-Culture pt-BR
    Set-WinHomeLocation -GeoId 32                                         # Brazil
} catch { Write-Warning "regiao/idioma: $_" }

Write-Host '==> Arquivos e desenvolvimento' -ForegroundColor Cyan
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' LongPathsEnabled 1
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' AllowDevelopmentWithoutDevLicense 1
$ss = "$cv\StorageSense\Parameters\StoragePolicy"
Set-Reg $ss '01' 1      # Storage Sense on
Set-Reg $ss '04' 1      # temp files
Set-Reg $ss '08' 1      # recycle bin
Set-Reg $ss '256' 30    # recycle bin: items older than 30 days
Set-Reg $ss '2048' 0    # run only when disk is low

Write-Host '==> Energia' -ForegroundColor Cyan
powercfg /change standby-timeout-ac 0      # never sleep on AC
powercfg /change hibernate-timeout-ac 0
powercfg /change monitor-timeout-ac 15

Stop-Process -Name explorer -Force   # applies taskbar changes
Write-Host "`nPronto. Idioma e teclado valem apos reiniciar." -ForegroundColor Green
exit 0
