# windows.ps1

## Objetivo
Preferências do Windows, separadas do `debloat.ps1` (que só remove).

## Requisitos
- Roda como administrador. Idempotente. Usa `Set-Reg` (`lib.ps1`): valor bloqueado vira aviso, não erro.
- Aparência: modo escuro (apps e sistema).
- Barra: ícones centralizados, sem busca, sem Visão de Tarefas. A ocultação automática fica com o mod `mac-island-dock` do Windhawk (`hiding.hideWhen = mouseAway`): ele liga e desliga o auto-ocultar do Windows sozinho, e um valor fixo no registro brigaria com ele.
- Iniciar: sem recomendados nem itens recentes (`HideRecommendedSection` só vale em Education/Enterprise).
- Região: fuso `E. South America Standard Time`, serviço `w32time` automático e `w32tm /resync`, idioma pt-BR (só troca a lista se o primeiro não for pt-BR; inclui ABNT2), cultura pt-BR, local Brasil.
- Arquivos: caminhos longos, modo desenvolvedor, Storage Sense (temporários, lixeira com 30 dias, só com pouco disco).
- Energia (na tomada): nunca suspende nem hiberna, tela desliga em 15 min.
- Reinicia o Explorer no fim; idioma e teclado valem após reiniciar.

## Fora do escopo
- Navegador padrão e associações de arquivo: o UCPD bloqueia.
- Transparência, sons, hibernação (`hiberfil.sys`).

## TODO
- Sem script de desfazer.
