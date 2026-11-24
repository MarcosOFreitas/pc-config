<#
.SYNOPSIS
  Windhawk mod settings in windhawk\mods.json.
  Windhawk has no command to install mods: install the missing ones in the app, then run again.
  Run:  .\windhawk.ps1            restore settings of installed mods (admin)
        .\windhawk.ps1 -WhatIf    show what would change
        .\windhawk.ps1 -Exportar  save this machine's mods and settings to the repo
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Exportar,
    # Registry root of the mods; only tests.ps1 changes it (scratch keys in HKCU, no admin needed).
    [string]$Raiz = 'HKLM:\SOFTWARE\Windhawk\Engine\Mods'
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib.ps1"
$root = $Raiz
$file = "$PSScriptRoot\windhawk\mods.json"

if (-not (Test-Path $root)) { Write-Host 'x Windhawk nao instalado ou sem mods. Rode .\install.ps1 e abra o Windhawk uma vez.' -ForegroundColor Red; exit 1 }

if ($Exportar) {
    $mods = [ordered]@{}
    foreach ($m in Get-ChildItem $root | Sort-Object PSChildName) {
        $p = Get-ItemProperty $m.PSPath
        $settings = [ordered]@{}
        $sk = "$($m.PSPath)\Settings"
        if (Test-Path -LiteralPath $sk) {
            $item = Get-Item -LiteralPath $sk
            foreach ($n in $item.GetValueNames()) { $settings[$n] = [ordered]@{ type = "$($item.GetValueKind($n))"; value = $item.GetValue($n) } }
        }
        # TODO: only flat Settings values are exported; nested subkeys are ignored.
        $mods[$m.PSChildName] = [ordered]@{ version = $p.Version; disabled = $p.Disabled; include = $p.Include; exclude = $p.Exclude; settings = $settings }
    }
    New-Item -ItemType Directory -Force (Split-Path $file) | Out-Null
    # One line per mod: small file and a diff you can read (5.1's pretty printer pads with thousands of spaces).
    $lines = $mods.Keys | ForEach-Object { '  ' + (ConvertTo-Json $_) + ': ' + ($mods[$_] | ConvertTo-Json -Depth 6 -Compress) }
    [IO.File]::WriteAllText($file, "{`n" + ($lines -join ",`n") + "`n}`n")
    Write-Host "Exportados $($mods.Count) mods para windhawk\mods.json. Revise o diff: o repo e publico." -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path $file)) { Write-Host 'x windhawk\mods.json nao existe. Rode -Exportar numa maquina configurada.' -ForegroundColor Red; exit 1 }
$mods = Get-Content $file -Raw | ConvertFrom-Json
$missing = @()
foreach ($mod in $mods.PSObject.Properties) {
    $id = $mod.Name; $want = $mod.Value
    $key = "$root\$id"
    if (-not (Test-Path $key)) { $missing += "$id $($want.version)"; continue }
    if ((Get-ItemProperty $key).Version -ne $want.version) { Write-Warning "${id}: instalado $((Get-ItemProperty $key).Version), exportado $($want.version)" }
    $changed = $false
    $targets = @(@{ Path = $key; Name = 'Disabled'; Value = [int]$want.disabled; Type = 'DWord' },
                 @{ Path = $key; Name = 'Include'; Value = "$($want.include)"; Type = 'String' },
                 @{ Path = $key; Name = 'Exclude'; Value = "$($want.exclude)"; Type = 'String' })
    foreach ($s in $want.settings.PSObject.Properties) { $targets += @{ Path = "$key\Settings"; Name = $s.Name; Value = $s.Value.value; Type = $s.Value.type } }
    foreach ($t in $targets) {
        $cur = Get-RegValue $t.Path $t.Name
        # An absent value is not an empty one: the mod would fall back to its own default.
        if ($null -ne $cur -and "$cur" -eq "$($t.Value)") { continue }
        if ($PSCmdlet.ShouldProcess("$id\$($t.Name)", 'definir')) { Set-Reg $t.Path $t.Name $t.Value $t.Type; $changed = $true }
    }
    # The engine reloads a mod when this timestamp changes.
    if ($changed) { Set-ItemProperty $key SettingsChangeTime ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) -Type DWord }
    Write-Host ("  {0} {1}" -f $(if ($changed) { '+' } else { '=' }), $id) -ForegroundColor $(if ($changed) { 'Green' } else { 'DarkGray' })
}

if ($missing) {
    Write-Host "`nInstale no Windhawk (aba Explorar) e rode de novo:" -ForegroundColor Yellow
    $missing | ForEach-Object { "  $_   https://windhawk.net/mods/$(($_ -split ' ')[0])" }
}
exit 0
