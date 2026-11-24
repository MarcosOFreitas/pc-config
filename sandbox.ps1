<#
.SYNOPSIS
  Tests the repo in a clean Windows Sandbox, unattended. Needs the Sandbox feature
  (Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All).
  Maps the repo read-only, copies it inside, runs bootstrap.ps1 and writes a log to
  a host folder; this script waits for the end and prints the log tail.
.EXAMPLE
  .\sandbox.ps1                       # debloat, windows, shell, install, vscode
  .\sandbox.ps1 -Passos install       # one step only
  .\sandbox.ps1 -Passos install,vscode -Categoria Midia -InstalarAntes Microsoft.VisualStudioCode   # short run
#>
param(
    # wsl needs nested virtualization and git.ps1 asks for input: neither works in the Sandbox.
    [ValidateSet('debloat', 'windows', 'shell', 'install', 'vscode')]
    [string[]]$Passos = @('debloat', 'windows', 'shell', 'install', 'vscode'),
    [int]$TimeoutMin = 90,
    [int]$Tail = 150,
    # Short run: install.ps1 only handles these apps.json categories (bootstrap is bypassed).
    [string[]]$Categoria,
    # winget IDs installed before the steps, e.g. Microsoft.VisualStudioCode for a vscode-only test.
    [string[]]$InstalarAntes
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path "$env:windir\System32\WindowsSandbox.exe")) { Write-Host 'x Windows Sandbox nao esta ativado.' -ForegroundColor Red; exit 1 }
# vmmemWindowsSandbox is the VM itself: it outlives the window if a run timed out.
if (Get-Process WindowsSandbox*, vmmemWindowsSandbox -ErrorAction SilentlyContinue) { Write-Host 'x Ja existe um Sandbox aberto; feche-o primeiro.' -ForegroundColor Red; exit 1 }

$out = Join-Path $env:TEMP 'pc-config-sandbox'
Remove-Item $out -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory $out | Out-Null

# Guest script: runs as the Sandbox admin user right after logon.
$guest = @'
$ErrorActionPreference = 'Continue'
Start-Transcript C:\out\log.txt -Force | Out-Null
$dest = "$HOME\pc-config"
robocopy C:\src $dest /E /NFL /NDL /NJH /NJS /NP | Out-Null

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host '==> winget ausente no Sandbox; instalando'
    # Microsoft's documented way to get winget in the Sandbox.
    try {
        $ProgressPreference = 'SilentlyContinue'
        Install-PackageProvider -Name NuGet -Force | Out-Null
        Install-Module Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
        Repair-WinGetPackageManager -AllUsers
        $env:Path += ";$env:LOCALAPPDATA\Microsoft\WindowsApps"
    } catch { Write-Host "x nao consegui instalar winget: $_" }
}
Write-Host ('winget: ' + $(if (Get-Command winget -ErrorAction SilentlyContinue) { winget --version } else { 'AUSENTE (teste usa so choco)' }))

foreach ($id in @(__ANTES__)) {
    winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Host
}
$categoria = @(__CATEGORIA__)
if ($categoria) {
    foreach ($step in @(__PASSOSQ__)) {
        if ($step -eq 'install') { & "$dest\install.ps1" -Categoria $categoria 2>&1 | Out-Host }
        else { & "$dest\$step.ps1" 2>&1 | Out-Host }
    }
} else {
    & "$dest\bootstrap.ps1" -Passos __PASSOS__ -Destino $dest 2>&1 | Out-Host
}

Write-Host "`n==== VERIFICACAO ===="
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
foreach ($c in 'winget','choco','uv','git','gh','code','pwsh','oh-my-posh','eza','bat','fd','fzf','jq','zoxide','node','cargo','rustup','docker','lazygit','make') {
    $r = if (Get-Command $c -ErrorAction SilentlyContinue) { 'ok  ' } else { 'FALTA' }
    Write-Host "  $r $c"
}
'done' | Set-Content C:\out\done.txt
Stop-Transcript | Out-Null
shutdown /s /t 5
'@
# Empty input must give an empty list: @('') would be truthy inside the guest.
$quote = { param($list) (@($list) | Where-Object { $_ } | ForEach-Object { "'$_'" }) -join ',' }
$guest = $guest.Replace('__PASSOS__', ($Passos -join ',')).Replace('__PASSOSQ__', (& $quote $Passos)).Replace('__CATEGORIA__', (& $quote $Categoria)).Replace('__ANTES__', (& $quote $InstalarAntes))
Set-Content (Join-Path $out 'run.ps1') $guest -Encoding utf8

$wsb = @"
<Configuration>
  <MemoryInMB>16384</MemoryInMB>
  <Networking>Default</Networking>
  <MappedFolders>
    <MappedFolder><HostFolder>$PSScriptRoot</HostFolder><SandboxFolder>C:\src</SandboxFolder><ReadOnly>true</ReadOnly></MappedFolder>
    <MappedFolder><HostFolder>$out</HostFolder><SandboxFolder>C:\out</SandboxFolder><ReadOnly>false</ReadOnly></MappedFolder>
  </MappedFolders>
  <LogonCommand><Command>powershell -ExecutionPolicy Bypass -File C:\out\run.ps1</Command></LogonCommand>
</Configuration>
"@
$wsbFile = Join-Path $out 'test.wsb'
Set-Content $wsbFile $wsb -Encoding utf8

Write-Host "==> Abrindo Sandbox (passos: $($Passos -join ', '); limite $TimeoutMin min)" -ForegroundColor Cyan
Start-Process WindowsSandbox.exe $wsbFile
$deadline = (Get-Date).AddMinutes($TimeoutMin)
while (-not (Test-Path "$out\done.txt") -and (Get-Date) -lt $deadline) { Start-Sleep 10 }

if (Test-Path "$out\done.txt") {
    Write-Host '==> Terminou' -ForegroundColor Green
    Start-Sleep 8
    Get-Process WindowsSandbox* -ErrorAction SilentlyContinue | Stop-Process -Force
} else {
    # Closing the window now would leave the VM running with nobody watching it.
    Write-Host '==> Tempo esgotado: o Sandbox continua rodando; o log segue sendo escrito e o Sandbox fecha sozinho no fim.' -ForegroundColor Red
}
Write-Host "Log completo: $out\log.txt`n"
if (Test-Path "$out\log.txt") { Get-Content "$out\log.txt" -Tail $Tail }
exit 0
