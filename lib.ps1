# Shared helpers. Dot-source: . "$PSScriptRoot\lib.ps1"

# Some values are locked by Windows (UCPD driver, tamper protection) even for admins.
# A locked value only warns, so the rest of the script still runs.
# Reads a value the way RegistryKey stores it. Get-ItemProperty returns negative DWords as huge
# unsigned numbers (-100 becomes 4294967196), which never equals what GetValue/JSON hold.
function Get-RegValue($path, $name) {
    $key = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    if ($key) { $key.GetValue($name) }
}

function Set-Reg($path, $name, $value, $type = 'DWord') {
    try {
        if (-not (Test-Path $path)) { New-Item -Path $path -Force -ErrorAction Stop | Out-Null }
        Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -ErrorAction Stop
    } catch {
        Write-Warning "$path\$name bloqueado pelo Windows, ignorado."
    }
}
