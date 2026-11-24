# shell.ps1 + profile.ps1

## Objetivo
Deixar o PowerShell 7 como shell do dia a dia, com tema, autocomplete e aliases.

## Requisitos: shell.ps1
- Sem `-SoPerfil`: roda `install.ps1 -Categoria Terminal` (exige admin).
- `$PROFILE` do pwsh passa a conter só `. '<repo>\profile.ps1'`. Perfil antigo vira `.bak`. Se já aponta para o repo, não mexe.
- Instala a Meslo Nerd Font (`oh-my-posh font install meslo`).
- Windows Terminal: perfil padrão = PowerShell 7 (`{574e775e-4f2a-5b96-ac1e-a2962a402336}`), fonte `MesloLGM Nerd Font`. `settings.json` antigo vira `.bak`.
- Windows Terminal vira o terminal padrão do Windows (`HKCU:\Console\%%Startup`).

## Requisitos: profile.ps1
- Tema Oh My Posh `amro`.
- PSReadLine: sugestões do histórico em lista, Tab = menu, setas buscam no histórico. Falha de predição em saída redirecionada é ignorada.
- Completions: `winget`, `gh`, `uv`. `zoxide` (`z`).
- Aliases do README. Cada um só é criado se a ferramenta existir.

## Decisões
- O PowerShell 5.1 não é removido: faz parte do Windows e o sistema depende dele.

## TODO
- Tema baixado da internet a cada init; guardar uma cópia no repo.
- Reescrever o `settings.json` do Windows Terminal perde comentários.
