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

# UCPD (Windows 11 24H2+) blocks any write to TaskbarDa with "unauthorized operation".
Assert (-not (Select-String -Path "$PSScriptRoot\debloat.ps1" -Pattern 'TaskbarDa' -Quiet)) 'debloat.ps1 does not write TaskbarDa'

# A protected registry value must not print a red error or stop debloat.
. ([scriptblock]::Create(((Get-Content "$PSScriptRoot\debloat.ps1" -Raw) -split '(?m)^Write-Host ''==> Ponto')[0]))
$warn = Set-Reg 'HKLM:\NoSuchHive\PcConfigTest' X 1 3>&1 2>&1
Assert ($warn -is [Management.Automation.WarningRecord]) 'Set-Reg turns a failed write into a warning'

if ($failed) { Write-Host "`n$failed falha(s)" -ForegroundColor Red; exit 1 }
Write-Host "`nTudo ok" -ForegroundColor Green
exit 0
