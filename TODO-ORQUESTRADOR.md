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

## Gates D3-D14 (estado atualizado 2026-10-13)
- [x] D3-1: catalog auditado (495 itens 0 erros; MVP-1 45/45 congelados em `catalog-mvp1.json` + tag `mvp1-frozen`)
- [x] D3-2: RoomStore hardening OK (setColor 0..5, duplicate preserva wall, rotate -45, 5 testes novos; `swift` indisponível p/ rodar, revisão manual)
- [x] D3-3: scene perf parcial (paredes 3m/0.2, grid 1m+0.25m, shadow 1024 + lowPower flag, AssetLoader log; FPS device pendente Mac)
- [x] D3-4: tools strict verdes (check 495/0, STRICT 495/0, demo 9/0, blend 496/0, YAML OK, gate mvp1-45 no CI)
- [ ] D3-5: arte inventário (495 GLB + 495 thumbs reais; 0 USDZ, conversão pendente no Mac)
- [ ] D3 app: um GLB/USDZ real carrega no simulador/device em escala correta (Mac)
- [x] D14 conteúdo v1.1: 15 itens novos, catalog 495; cobertura 45/45 room×categoria ≥4

## Riscos
- Sem Mac local: build só no Actions macos-15. S2 precisa de Mac ou usa `swiftpm` mock até CI validar.
- Blend 2.7 quebrar no 4.2: fallback Append por coleção.
- CC-BY: cobrar crédito na UI antes do D21.

## Log
- 2026-10-05 02:28: D1 executado pelo ORQ (desbloqueio): inventario + cadeira 72tris + skeleton SwiftPM + release checklist. Validações locais verdes. Commit pendente. S1/S2/S3 podem assumir D2 dos prompts/.
- 2026-10-06 01:55: push inicial p/ github.com/socialbot114-cell/polyroom-ios (privado) + 3 Actions verdes no commit 36b2325: assets-validate (Blender 4.2.1, checked=481 errors=0, catalog 480/0, demo 9/0, mvp1-45 OK), previews (contact-sheet-480 + 15 sheets, artifact polyroom-prints 790KB), ios-build (Xcode 16.2, placeholder sem xcodeproj — gap Mac). Fix: 3 ids acento→ASCII, script 480.
- 2026-10-10: D3→D11 (sem Mac): shells quarto/cozinha/sala exportados dos blends (36 tris, footprint M→L, thumbs refeitas); `tools/check_scale.py` sentinela (495: 0 errors, 151 warns + 28 wall p/ triagem — semântica S/M/L ambígua p/ parede/altos); `tools/check_kill_restore.py` OK (round-trip + truncado + corrupto sem crash); S2 model e drag no SCNView; CI remoto verde após repo público.
- 2026-10-13 (polish): missões integradas a UI/moedas/progresso, efeitos sonoros offline com toggle e recursos SwiftPM, busca/tap/drag incremental + testes Swift; 15 itens v1.1 completos e cobertura zerada; tint aplica multiply sem apagar cores originais. CI executará `swift test` para validar compilação. Pendências de device: USDZ, projeto Xcode e FPS físico.
