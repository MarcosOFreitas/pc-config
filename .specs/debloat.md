# debloat.ps1

## Objetivo
Tirar apps e serviços que o Windows instala por padrão e ajustar desempenho.

## Requisitos
- Roda como administrador. Cria ponto de restauração antes de qualquer mudança.
- Remove apps pré-instalados para todos os usuários e para novos usuários (provisioned).
- Desliga telemetria (`AllowTelemetry=0`, serviços `DiagTrack` e `dmwappushservice`), ID de anúncio, sugestões, Bing no menu Iniciar, widgets.
- Explorer: mostra extensões e ocultos, abre em "Este PC", menu de contexto clássico.
- Desempenho: plano Ultimate (ou Alto desempenho), Game DVR off, apps em segundo plano off, agendamento de GPU por hardware, `SystemResponsiveness=10`.
- Reinicia o Explorer no fim; o usuário reinicia o PC.

## Fora do escopo
- Remover Outlook, Xbox, Edge ou PowerShell 5.1.
- Hibernação (máquina pode ser notebook).

## TODO
- Script de desfazer. Hoje só o ponto de restauração volta atrás.
