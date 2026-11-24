# wsl.ps1

## Objetivo
WSL 2 com Ubuntu e limites de recurso sensatos.

## Requisitos
- Roda como administrador.
- `wsl --update`; instala a distro (`-Distro`, padrão `Ubuntu`) com `--no-launch` se ainda não existir. O usuário Linux é criado no primeiro `wsl`.
- Cria `~/.wslconfig` só se não existir: `memory` = metade da RAM, `processors` = metade das CPUs, `swap=4GB`, `autoMemoryReclaim=gradual`, `sparseVhd=true`.
- `.wslconfig` existente nunca é sobrescrito.

## Fora do escopo
- Configurar o Linux por dentro (pacotes, dotfiles).
