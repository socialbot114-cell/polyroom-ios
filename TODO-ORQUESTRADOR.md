# TODO-ORQUESTRADOR — acompanhamento vivo (eu atualizo diário)

## Sessões
- ORQ: esta sessão (gerencia)
- S1 Arte: PID 299415? confirmar com `readlink /proc/*/cwd` — pasta polyroom
- S2 iOS: PID 299653? confirmar
- S3 QA-CI: PID 299899? confirmar
> Se PIDs mudarem, rodar `for pid in $(pgrep -f opencode); do echo -n "$pid: "; readlink /proc/$pid/cwd; done`

## Gates
- [ ] D1: repo + Actions v0 verde
- [ ] D3: 1 prop teste carrega no app (escala ok)
- [ ] D7 I1: 3 shells + 16 itens + save/load
- [ ] D14 I2: ~35 itens, 6 categorias cobertas
- [ ] D21 Beta v0.9
- [ ] D30 v1.0-mvp1 tag

## Fila hoje (D1)
- [ ] S3: `git init`, criar repo `polyroom-ios`, push esqueleto, ativar Actions
- [ ] S1: instalar Blender 4.2.1, baixar 24957, criar `art-source/_REF_INVENTARIO.md`
- [ ] S2: criar `ios-app/Polyroom` Xcode + `RoomSceneView` placeholder + `SaveManager`
- [ ] ORQ: revisar D1 fim do dia, atualizar este arquivo

## Riscos
- Sem Mac local: build só no Actions macos-15. S2 precisa de Mac ou usa `swiftpm` mock até CI validar.
- Blend 2.7 quebrar no 4.2: fallback Append por coleção.
- CC-BY: cobrar crédito na UI antes do D21.

## Log
- 2026-10-05: esqueleto criado pelo orquestrador, prompts emitidos, aguardando S1/S2/S3 assumirem.
