# windows.ps1

## Objetivo
Preferências do Windows, separadas do `debloat.ps1` (que só remove).

## Requisitos
- Roda como administrador. Idempotente. Usa `Set-Reg` (`lib.ps1`): valor bloqueado vira aviso, não erro.
- Aparência: modo escuro (apps e sistema).
- Barra: ícones centralizados, ocultação automática (byte 8 de `StuckRects3\Settings` = 3), sem busca, sem Visão de Tarefas.
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
- `StuckRects3` não existe antes do primeiro login: a barra não é ocultada nesse caso.
