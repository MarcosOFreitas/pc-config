#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Removes Windows bloat, cuts telemetry/ads and applies performance tweaks.
  Creates a restore point first. Reboot after running.
#>
# TODO: no undo script yet; the restore point is the only way back.
$ErrorActionPreference = 'Continue'

# Some values are locked by Windows (UCPD driver, tamper protection) even for admins.
# A locked value only warns, so the rest of the script still runs.
function Set-Reg($path, $name, $value, $type = 'DWord') {
    try {
        if (-not (Test-Path $path)) { New-Item -Path $path -Force -ErrorAction Stop | Out-Null }
        Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -ErrorAction Stop
    } catch {
        Write-Warning "$path\$name bloqueado pelo Windows, ignorado."
    }
}

Write-Host '==> Ponto de restauracao' -ForegroundColor Cyan
Enable-ComputerRestore -Drive "$env:SystemDrive\"
Checkpoint-Computer -Description 'PC-Config debloat' -RestorePointType MODIFY_SETTINGS

Write-Host '==> Removendo apps pre-instalados' -ForegroundColor Cyan
$bloat = @(
    'Clipchamp.Clipchamp'
    'Microsoft.BingNews'
    'Microsoft.BingWeather'
    'Microsoft.BingSearch'
    'Microsoft.GetHelp'
    'Microsoft.Getstarted'
    'Microsoft.MicrosoftOfficeHub'
    'Microsoft.MicrosoftSolitaireCollection'
    'Microsoft.MicrosoftStickyNotes'
    'Microsoft.People'
    'Microsoft.PowerAutomateDesktop'
    'Microsoft.Todos'
    'Microsoft.WindowsFeedbackHub'
    'Microsoft.WindowsMaps'
    'Microsoft.ZuneMusic'
    'Microsoft.YourPhone'
    'MicrosoftCorporationII.QuickAssist'
    'MicrosoftTeams'
    'MSTeams'
    'Microsoft.549981C3F5F10'   # Cortana
    'MicrosoftWindows.Client.WebExperience'   # Widgets (registry toggle is locked by UCPD)
)
foreach ($app in $bloat) {
    Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $app |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
    Write-Host "  - $app"
}

Write-Host '==> Telemetria' -ForegroundColor Cyan
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' AllowTelemetry 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' Enabled 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' TailoredExperiencesWithDiagnosticDataEnabled 0
foreach ($svc in 'DiagTrack', 'dmwappushservice') {
    Stop-Service $svc -Force -ErrorAction SilentlyContinue
    Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
}

Write-Host '==> Anuncios, sugestoes e Bing no menu Iniciar' -ForegroundColor Cyan
$cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
foreach ($n in 'SilentInstalledAppsEnabled', 'SystemPaneSuggestionsEnabled', 'SubscribedContent-338388Enabled',
    'SubscribedContent-338389Enabled', 'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled',
    'SoftLandingEnabled', 'ContentDeliveryAllowed', 'OemPreInstalledAppsEnabled', 'PreInstalledAppsEnabled') {
    Set-Reg $cdm $n 0
}
Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' DisableSearchBoxSuggestions 1
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' Start_IrisRecommendations 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' AllowNewsAndInterests 0   # widgets

Write-Host '==> Explorer' -ForegroundColor Cyan
$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-Reg $adv HideFileExt 0
Set-Reg $adv Hidden 1
Set-Reg $adv LaunchTo 1              # open "This PC"
Set-Reg 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' '(default)' '' 'String'  # classic context menu

Write-Host '==> Performance' -ForegroundColor Cyan
# High performance plan (Ultimate when available).
$ultimate = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
if ($ultimate -match '([0-9a-f-]{36})') { powercfg -setactive $Matches[1] } else { powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c }
Set-Reg 'HKCU:\System\GameConfigStore' GameDVR_Enabled 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' AllowGameDVR 0
Set-Reg 'HKCU:\Control Panel\Desktop' MenuShowDelay '0' 'String'
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' GlobalUserDisabled 1
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' HwSchMode 2   # hardware GPU scheduling
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' SystemResponsiveness 10

Stop-Process -Name explorer -Force
Write-Host "`nPronto. Reinicie o PC." -ForegroundColor Green
exit 0
