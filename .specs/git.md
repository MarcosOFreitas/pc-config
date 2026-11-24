# git.ps1

## Objetivo
Deixar git e GitHub prontos numa máquina nova: identidade, config global, chave SSH e login.

## Requisitos
- Sai com erro se `git`, `gh` ou `ssh-keygen` faltarem.
- Nome e email: usa o que já está no `~/.gitconfig`; senão pergunta. **Nunca ficam no repo** (repo público). Sugere o email noreply do GitHub.
- Config global: `init.defaultBranch=main`, `pull.rebase`, `push.autoSetupRemote`, `fetch.prune`, `rebase.autoStash`, `core.autocrlf`, `core.editor=code --wait`, `core.sshCommand` = OpenSSH do Windows.
- Chave `~/.ssh/id_ed25519`: cria só se não existir; `ssh-keygen` pede senha (recomendado).
- `ssh-agent` automático e com a chave carregada (precisa de admin; sem admin, só avisa).
- GitHub: `gh auth login --web` se não logado, escopo `admin:public_key`, envia só a chave **pública** se ainda não cadastrada, com o nome do computador como título.
- Testa com `ssh -T git@github.com`.

## Fora do escopo
- Assinatura de commits (GPG/SSH signing).
