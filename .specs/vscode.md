# vscode.ps1

## Objetivo
Reproduzir extensões e configurações do VS Code em qualquer máquina.

## Requisitos
- Sai com erro se `code` não estiver no PATH.
- Instala cada extensão de `vscode/extensions.txt` que ainda não está instalada.
- Copia `vscode/settings.json` e `vscode/keybindings.json` para `%APPDATA%\Code\User`. Arquivos antigos viram `.bak`.
- `-Exportar` faz o caminho inverso (máquina > repo). Revisar o diff antes do commit.
- `extensions.txt` lista só extensões principais; dependências (Pylance, debugpy, extras do Jupyter) vêm sozinhas.

## Configuração escolhida
- Linguagens: Python (Ruff), JS/TS (Prettier + ESLint), Rust (rust-analyzer + clippy).
- Ao salvar: formatar, `source.fixAll`, organizar imports, aparar espaços, linha final.
- Visual: Dracula, ícones Material, minimap off, guias de colchetes, sticky scroll.
- Leitores: Markdown Preview Enhanced, Edit CSV + Rainbow CSV, Better Comments + Todo Tree.

## Fora do escopo
- `mcp.json` (pode ter tokens).

## TODO
- Extensões tiradas da lista não são desinstaladas.
