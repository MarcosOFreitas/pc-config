# CLAUDE.md

Windows 11 machine setup in PowerShell. See README.md for usage and `.specs/` for per-script requirements.

## Rules
- Scripts must run on **Windows PowerShell 5.1** (a fresh machine has no pwsh yet). No `??`, `?.`, ternary, `-AsHashtable`. Only `profile.ps1` is pwsh-only.
- Every script is idempotent: skip what is already installed/configured; back up a user file as `.bak` before overwriting it.
- App list lives only in `apps.json`. Order per entry: `uv` > `winget` > `choco`. Store IDs (`9XXXXXXXXXXX`) use `--source msstore`.
- Python tools and interpreter go through `uv`, never pip/winget Python.
- `profile.ps1` is loaded from `$PROFILE` by path: do not move or rename it.
- **Public repo.** No secrets and no personal data (name, email, keys, tokens, machine paths like `C:\Users\<name>`). Ask for them at run time; store only in user files outside the repo.
- Scripts end with `exit 0` on success and `exit 1` on failure: `bootstrap.ps1` reads `$LASTEXITCODE`.
- Mark known gaps with `# TODO:` comments; keep `.specs/` in sync when behavior changes.

## Check before commit
```powershell
foreach ($f in Get-ChildItem *.ps1) { $e = $null; [void][Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$null, [ref]$e); "$($f.Name): $($e.Count) errors" }
```
Run it in both `powershell` and `pwsh`.
