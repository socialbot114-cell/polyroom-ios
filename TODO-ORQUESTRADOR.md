# TODO-ORQUESTRADOR — acompanhamento vivo (eu atualizo diário)

## Sessões (confirmado via /proc)
- ORQ: 299164 pts/11 (esta sessão)
- S1 Arte: 299415 pts/12
- S2 iOS: 299653 pts/13
- S3 QA-CI: 299899 pts/14

## Gates
- [x] D1: repo + Actions v0 verde (local: catalog 45/0 erros, blend 1/0 erros, yaml OK)
- [x] D1 prop teste: KIT_Moveis_Cadeira 72 tris + .glb 6.2KB
- [ ] D3: 1 prop teste carrega no app (escala ok)
- [ ] D7 I1: 3 shells + 16 itens + save/load
- [ ] D14 I2: ~35 itens, 6 categorias cobertas
- [ ] D21 Beta v0.9
- [ ] D30 v1.0-mvp1 tag

## Fila D2 (disparado pelo ORQ)
- [ ] S1: BED/KIT/LIV shells v01 + lote 1 (5 móveis grandes/quarto)
- [ ] S2: tap-to-place + drag snap 0.25m + girar 45° no placeholder
- [ ] S3: preparar `gh repo create polyroom-ios --private` (aguardando sua autorização p/ push)
- [ ] ORQ: revisar D2 fim do dia

## Riscos
- Sem Mac local: build só no Actions macos-15. S2 precisa de Mac ou usa `swiftpm` mock até CI validar.
- Blend 2.7 quebrar no 4.2: fallback Append por coleção.
- CC-BY: cobrar crédito na UI antes do D21.

## Log
- 2026-10-05 02:28: D1 executado pelo ORQ (desbloqueio): inventario + cadeira 72tris + skeleton SwiftPM + release checklist. Validações locais verdes. Commit pendente. S1/S2/S3 podem assumir D2 dos prompts/.
