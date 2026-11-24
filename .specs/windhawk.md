# windhawk.ps1

## Objetivo
Levar as configurações dos mods do Windhawk para uma máquina nova.

## Como o Windhawk guarda dados
- Registro `HKLM\SOFTWARE\Windhawk\Engine\Mods\<id>`: `Version`, `Disabled`, `Include`, `Exclude`, `SettingsChangeTime` e subchave `Settings` (valores planos, String ou DWord).
- Fontes em `%ProgramData%\Windhawk\ModsSource`, binários compilados em `Engine\Mods`.
- Não existe comando para instalar mods; só a interface (`windhawk.exe` aceita `-tray-only`, `-exit`, `-restart`, `-safe-mode`).

## Requisitos
- `-Exportar` (sem admin): grava `windhawk/mods.json`, uma linha por mod (id, versão, `disabled`, `include`, `exclude`, `settings` com tipo e valor).
- Sem parâmetro (admin): para cada mod do JSON **já instalado**, grava só o que difere; atualiza `SettingsChangeTime` (a engine recarrega o mod por ele). Avisa se a versão instalada difere da exportada.
- Mods ausentes: lista id, versão e link `https://windhawk.net/mods/<id>`; o usuário instala pela interface e roda de novo.
- `-WhatIf` mostra o que mudaria sem escrever.
- Comparação usa `Get-RegValue` (`GetValue`): `Get-ItemProperty` lê DWord negativo (`-100`) como `4294967196`.

## Fora do escopo
- Binários e fontes dos mods (grandes, de terceiros), perfil de UI do Windhawk, configurações do app.
- Repo público: revisar o diff do JSON antes do commit (hoje só nomes de processos e um atalho do `hosts`).

## TODO
- Subchaves aninhadas em `Settings` são ignoradas.
- Não testado em máquina limpa (o Sandbox não valida injeção no Explorer).
