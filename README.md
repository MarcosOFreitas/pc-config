# PC-Config

Scripts para configurar uma máquina Windows 11 do zero: apps, shell, VS Code e debloat.

## Uso

Abra o PowerShell **como administrador** na pasta do repo:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\debloat.ps1   # remove bloat, telemetria, ajustes de desempenho (reinicie depois)
.\shell.ps1     # PowerShell 7, ferramentas de terminal, perfil, fonte, Windows Terminal
.\install.ps1   # demais apps de apps.json
.\vscode.ps1    # extensões e configs do VS Code
```

Cada script roda sozinho e pode ser repetido: o que já está instalado é pulado.

| Script | O que faz | Opções |
|---|---|---|
| `install.ps1` | Instala os apps de `apps.json`: `uv` > `winget` > `choco` (fallback) | `-Categoria Dev,Terminal` |
| `shell.ps1` | Categoria `Terminal` + `$PROFILE` apontando para `profile.ps1` + Meslo Nerd Font + Windows Terminal padrão | `-SoPerfil` |
| `profile.ps1` | Perfil do pwsh: tema Oh My Posh `amro`, autocomplete, zoxide, aliases | — |
| `debloat.ps1` | Ponto de restauração, remove apps, telemetria, anúncios, ajustes de Explorer e desempenho | — |
| `vscode.ps1` | Instala `vscode/extensions.txt` e copia `vscode/settings.json` e `keybindings.json` | `-Exportar` |

## Adicionar um app

Edite `apps.json`, na categoria certa:

```jsonc
{ "winget": "Publisher.App", "choco": "app" }   // winget com fallback choco
{ "winget": "9XXXXXXXXXXX", "nome": "App" }     // Microsoft Store
{ "uv": "ruff" }                                 // ferramenta Python (uv tool install)
```

## Aliases do perfil

| Alias | Comando |
|---|---|
| `ls` / `ll` / `lt` | `eza` (lista, detalhada, árvore) |
| `cat` | `bat` |
| `z <pasta>` | `zoxide` |
| `lg` / `g` / `gs` | `lazygit` / `git` / `git status -sb` |
| `..` / `...` | sobe 1 / 2 pastas |
| `which`, `touch` | equivalentes do Unix |

## Specs

Requisitos e decisões de cada script em [`.specs/`](.specs/).
