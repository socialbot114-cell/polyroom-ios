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

## Fila D2-D3 (2026-10-06 — 6 agentes disparados, ORQ Docs só registra)
- [ ] A1 catalog: auditar `catalog.json` 480 itens (recount 15 categorias, matriz GAPS, `check_catalog.py` 480/0 erros)
- [ ] A2 iOS RoomStore: hardening (wall mount, snap/clamp, rotate/color/duplicate/remove, save corrupto)
- [ ] A3 iOS scene: perf (<50k tris, 60/30fps) + `AssetLoader` fallback glb/teal sem crash
- [ ] A4 tools: strict (`check_catalog`/`demo_load`/`check_blend` p/ 480, `ALLOW_MISSING=0` doc)
- [ ] A5 arte: inventário (481 blends × 480 glb × 0 usdz, thumbs, `bed_moveis_cadeira` + pipeline usdz Mac)
- [ ] A6 QA-CI: bug-bash device (BB-13 snapshot + BB-14 onboarding/sobre) + `ios-build`/`assets-validate` verdes

## Gates D3 (2026-10-06 — propostos, NÃO feitos)
- [ ] D3-1: catalog 480 auditado (matriz refeita, 0 erros)
- [ ] D3-2: RoomStore hardening OK (kill-restore + corrupto + limites)
- [ ] D3-3: scene perf medida (fps + tris + fallback)
- [ ] D3-4: tools strict verdes p/ 480
- [ ] D3-5: arte inventário fechado (480 glb / 0 usdz plano Mac)

## Riscos
- Sem Mac local: build só no Actions macos-15. S2 precisa de Mac ou usa `swiftpm` mock até CI validar.
- Blend 2.7 quebrar no 4.2: fallback Append por coleção.
- CC-BY: cobrar crédito na UI antes do D21.

## Log
- 2026-10-05 02:28: D1 executado pelo ORQ (desbloqueio): inventario + cadeira 72tris + skeleton SwiftPM + release checklist. Validações locais verdes. Commit pendente. S1/S2/S3 podem assumir D2 dos prompts/.
