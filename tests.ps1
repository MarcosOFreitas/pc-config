<#
.SYNOPSIS
  Static checks for the repo scripts. Run in both `powershell` and `pwsh`:
    .\tests.ps1
#>
$failed = 0
function Assert($ok, $msg) {
    if ($ok) { Write-Host "  ok   $msg" -ForegroundColor Green }
    else { Write-Host "  FAIL $msg" -ForegroundColor Red; $script:failed++ }
}
$scripts = Get-ChildItem "$PSScriptRoot\*.ps1"

foreach ($f in $scripts) {
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$null, [ref]$errors)
    Assert ($errors.Count -eq 0) "$($f.Name) parses"
}

# 'Administrators' is the English group name; on pt-BR Windows it is 'Administradores',
# so IsInRole('Administrators') is false even in an elevated shell.
foreach ($f in $scripts | Where-Object Name -ne 'tests.ps1') {
    Assert (-not (Select-String -Path $f.FullName -Pattern "IsInRole\('" -Quiet)) "$($f.Name) admin check is language independent"
}

# The mac-island-dock Windhawk mod switches Windows' taskbar auto-hide on and off itself;
# a permanent registry auto-hide would fight it.
Assert (-not (Select-String -Path "$PSScriptRoot\windows.ps1" -Pattern 'StuckRects3' -Quiet)) 'windows.ps1 leaves taskbar auto-hide to the Windhawk mod'

# Public repo: no machine-specific user paths in any script (tests.ps1 itself excluded).
foreach ($f in $scripts | Where-Object Name -ne 'tests.ps1') {
    Assert (-not (Select-String -Path $f.FullName -Pattern 'C:\\Users\\[A-Za-z]' -Quiet)) "$($f.Name) has no hardcoded user path"
}

# UCPD (Windows 11 24H2+) blocks any write to TaskbarDa with "unauthorized operation".
Assert (-not (Select-String -Path "$PSScriptRoot\debloat.ps1" -Pattern 'TaskbarDa' -Quiet)) 'debloat.ps1 does not write TaskbarDa'

# Without winget (Sandbox, LTSC) install.ps1 must fall back to choco instead of crashing.
Assert (Select-String -Path "$PSScriptRoot\install.ps1" -Pattern 'Get-Command winget' -Quiet) 'install.ps1 checks that winget exists'

# A protected registry value must not print a red error or stop debloat.
foreach ($n in 'debloat', 'windows', 'windhawk') {
    Assert (Select-String -Path "$PSScriptRoot\$n.ps1" -Pattern 'lib\.ps1' -Quiet) "$n.ps1 uses the shared Set-Reg from lib.ps1"
}
. "$PSScriptRoot\lib.ps1"
$warn = Set-Reg 'HKLM:\NoSuchHive\PcConfigTest' X 1 3>&1 2>&1
Assert ($warn -is [Management.Automation.WarningRecord]) 'Set-Reg turns a failed write into a warning'

# Negative DWords (Windhawk glassOpacity=-100): Get-ItemProperty reads them as 4294967196,
# so comparing against exported values must use the same API as the export (GetValue).
$tmp = 'HKCU:\Software\PcConfigTests'
Set-Reg $tmp neg -100 'DWord'
$read = if (Get-Command Get-RegValue -ErrorAction SilentlyContinue) { Get-RegValue $tmp neg } else { $null }
Remove-Item $tmp -Recurse -ErrorAction SilentlyContinue
Assert ($read -eq -100) 'Get-RegValue reads a negative DWord as -100'

if ($failed) { Write-Host "`n$failed falha(s)" -ForegroundColor Red; exit 1 }
Write-Host "`nTudo ok" -ForegroundColor Green
exit 0
