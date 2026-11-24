# install.ps1

## Objetivo
Instalar os apps de `apps.json` numa máquina nova, sem interação.

## Requisitos
- Roda como administrador, no Windows PowerShell 5.1 ou 7.
- Para cada entrada, tenta em ordem: `uv` > `winget` > `choco`. Passa para o próximo só se o anterior falhar.
- `uv: "python"` instala o interpretador (`uv python install --default`); outro valor usa `uv tool install`.
- IDs da Microsoft Store (`9` + 11 caracteres) usam `--source msstore`.
- App já instalado é pulado (`winget list --exact`).
- Chocolatey é instalado sozinho só quando a primeira entrada precisa dele.
- `-Categoria` limita às categorias pedidas.
- No fim, lista o que falhou e sai com código 1.
- `-Exportar` (sem admin): compara `winget export` com `apps.json` e lista o que está instalado e fora da lista, ignorando runtimes.

## Fora do escopo
- Games, runtimes (VCRedist, .NET, WindowsAppRuntime) e dependências que os apps puxam sozinhos.
- Desinstalar apps que saíram da lista.

## TODO
- `--preview` em `uv python install --default`.
- Store pode exigir conta Microsoft logada.
