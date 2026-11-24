# PC-Config

Scripts para configurar uma máquina Windows 11 do zero: apps, shell, VS Code, git, WSL e debloat.

## Máquina nova

Abra o PowerShell **como administrador** e rode:

```powershell
irm https://raw.githubusercontent.com/MarcosOFreitas/pc-config/main/bootstrap.ps1 | iex
```

Baixa o repo para `~\pc-config`, roda todos os scripts na ordem e deixa a pasta como clone git (atualize com `git pull`). Reinicie no fim.

### Escolher passos

`irm | iex` não aceita parâmetros; para passá-los use `[scriptblock]::Create`:

```powershell
# tudo menos o debloat
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MarcosOFreitas/pc-config/main/bootstrap.ps1))) -Pular debloat

# PC já configurado: só apps e VS Code, usando o clone que já existe
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MarcosOFreitas/pc-config/main/bootstrap.ps1))) -Passos install,vscode -Destino $HOME\dev\pc-config
```

| Parâmetro | Valores | Padrão |
|---|---|---|
| `-Passos` | `debloat`, `windows`, `shell`, `install`, `windhawk`, `wsl`, `vscode`, `git` (ordem fixa) | todos |
| `-Pular` | mesmos valores | nenhum |
| `-Destino` | pasta do repo | `~\pc-config` |

Num PC já configurado, rode `.\vscode.ps1 -Exportar` antes: o passo `vscode` sobrescreve `settings.json`.

## Scripts avulsos

Abra o PowerShell **como administrador** na pasta do repo:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\debloat.ps1   # remove bloat, telemetria, ajustes de desempenho (reinicie depois)
.\windows.ps1   # preferências: modo escuro, barra de tarefas, Iniciar, região, arquivos, energia
.\shell.ps1     # PowerShell 7, ferramentas de terminal, perfil, fonte, Windows Terminal
.\install.ps1   # demais apps de apps.json
.\windhawk.ps1  # restaura as configurações dos mods do Windhawk (instale os mods antes)
.\wsl.ps1       # WSL + Ubuntu + .wslconfig
.\vscode.ps1    # extensões e configs do VS Code
.\git.ps1       # git config, chave SSH, login no GitHub
```

Cada script roda sozinho e pode ser repetido: o que já está instalado é pulado.

| Script | O que faz | Opções |
|---|---|---|
| `bootstrap.ps1` | Baixa o repo e roda todos os scripts abaixo | — |
| `install.ps1` | Instala os apps de `apps.json`: `uv` > `winget` > `choco` (fallback) | `-Categoria Dev,Terminal`, `-Exportar` (lista apps instalados fora do `apps.json`) |
| `windows.ps1` | Preferências do Windows: tema escuro; barra centralizada, sem busca nem Visão de Tarefas (a ocultação automática é do mod `mac-island-dock`); Iniciar sem recomendados; fuso de Brasília, hora automática, pt-BR ABNT2; caminhos longos, modo desenvolvedor, Storage Sense; sem suspender na tomada | — |
| `windhawk.ps1` | Restaura configurações de `windhawk/mods.json` nos mods já instalados e lista os que faltam instalar (o Windhawk não tem comando de instalação) | `-Exportar` (salva as da máquina), `-WhatIf` |
| `sandbox.ps1` | Testa o bootstrap num Windows Sandbox limpo, sem intervenção, e mostra o log | `-Passos`, `-TimeoutMin`, `-Categoria` e `-InstalarAntes` (rodada curta, sem o bootstrap) |
| `tests.ps1` | Checagens estáticas dos scripts (rode antes de commitar) | — |
| `git.ps1` | Nome/email (perguntados na hora), config global, chave SSH ed25519, `gh auth login` e envio da chave pública | — |
| `wsl.ps1` | WSL + Ubuntu, `.wslconfig` com metade da RAM e das CPUs | `-Distro` |
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

## Dados pessoais

O repo é público. Nome, email, chaves SSH e tokens **não** ficam aqui: o `git.ps1` pergunta na hora e grava só no `~/.gitconfig` e em `~/.ssh`. O `.gitignore` bloqueia chaves, `.env` e `mcp.json`.

## Specs

Requisitos e decisões de cada script em [`.specs/`](.specs/).
