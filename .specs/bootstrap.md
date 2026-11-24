# bootstrap.ps1

## Objetivo
Configurar um PC recém-formatado com um único comando, sem git instalado:

```powershell
irm https://raw.githubusercontent.com/MarcosOFreitas/pc-config/main/bootstrap.ps1 | iex
```

## Requisitos
- Roda no Windows PowerShell 5.1, como administrador (senão avisa e para).
- Baixa o zip da `main` para `~\pc-config` e desbloqueia os arquivos. Pasta durável: o `$PROFILE` aponta para ela.
- Se `~\pc-config` já é clone git, usa como está.
- Ordem: `debloat` > `shell` > `install` > `wsl` > `vscode` > `git`. Falha num passo não para os outros; no fim lista o que falhou.
- Atualiza o PATH da sessão entre passos.
- No fim, transforma a pasta em clone git ligado a `origin/main`.

## Decisões
- Repo público: download sem autenticação.
