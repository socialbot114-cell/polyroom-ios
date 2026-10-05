# ROADMAP 30 DIAS — Polyroom MVP 3 quartos (offline + Actions)

Orquestrador acompanha por `TODO-ORQUESTRADOR.md`. CI deve estar verde no D3 e nunca quebrar depois.

## SEMANA 1 (D1-D7) — Fundação
**D1:** S3 cria repo + push esqueleto + Actions v0. S1 instala Blender 4.2, baixa 24957, documenta `art-source/_REF_INVENTARIO.md`. S2 cria projeto Xcode local (Mac) ou SwiftPM skeleton no Linux + `SaveManager` + `catalog.json` mock.
- Entrega: Actions `ios-build` compila placeholder + `assets-validate` lista arquivos. Orquestrador valida.

**D2-D3:** S1 converte REF para 4.2, separa BED/KIT/LIV, entrega 3 shells low limpos + 1 prop teste (`cadeira`). S2: `RoomSceneView` com grid + orbit + 3 cubos-shell trocáveis. S3: `check_blend.py` + `check_catalog.py` funcionais.
- Gate: 1 USDZ/GLB teste carrega no app. Se quebrar escala, congela e corrige PIPELINE.

**D4-D5:** S1: lote 1 = 15 móveis grandes (5/quarto). S2: Catalog bottom-sheet por categoria + tap-to-place + mover. S3: thumbs pipeline + TestFlight interno v0.1.
**D6-D7:** Integração I1: 3 shells + 16 itens no app, save/load JSON. QA modo avião, FPS. Revisão orquestrador, congela contratos v1.

## SEMANA 2 (D8-D14) — Variedade
**D8-D10:** S1 lote 2 = 15 acessórios (panela, prato, livro, quadro, TV, etc). S2: girar 45°, duplicar, excluir, snap 0.25m. S3: amplia catalog para 30 itens, teste kill-restore.
**D11-D13:** S1 lote 3 = 15 sub-itens/texteis/plantas/iluminação. S2: recolor tintable 6 swatches + inspector flutuante. S3: checklist cozyCoins local + desbloqueio quartos.
**D14:** Integração I2: 3 quartos x ~30-35 itens. Teste variedade: cada categoria tem >=4 opções por quarto. Gate orquestrador.

## SEMANA 3 (D15-D21) — Polish offline
**D15-D17:** S1: atlas 1024/quarto, LOD leve, thumbs 256 finais. S2: sombras suaves, haptics, sons wav offline, snapshot PNG share. S3: onboarding 3 passos + Sobre com crédito CC-BY + `GDD` final.
**D18-D20:** S2: performance (occlusion, <50k tris cena, cache SCN), SE2 30fps. S1 corrige overbudget. S3: matriz teste iPhone 12/SE/16 simulator + device real se houver.
**D21:** Beta v0.9 TestFlight. Congela features.

## SEMANA 4 (D22-D30) — QA + Ship MVP-1
**D22-D25:** S3 lidera bug bash: top 20 bugs, S1/S2 corrigem em 48h. Foco: save corrupt, z-fight paredes, usdz faltando, thumb quebrada.
**D26-D27:** S2: ícones, splash, `Info.plist` offline (`NSAppTransportSecurity` sem exceção), version 1.0(1). S1: `art-ios/FINAL_*` + inventário tris. S3: `RELEASE-CHECKLIST.md` + vídeo 30s.
**D28-D30:** Orquestrador aprova, tag `v1.0-mvp1`, upload TestFlight, retrospectiva + plano v1.1 (mais quartos/estação/animação porta).

## RACI
- Orquestrador: aprova gates D7/D14/D21/D30, resolve conflito pasta, mantém TODO.
- S1 nunca quebra `catalog.json`, S2 nunca quebra `art-source`, S3 dono de `catalog.json` + CI.
- Regra: PR pequeno diário, CI verde, sem push direto main após D3.

## Métricas
- 3 shells + 45 SKUs, 6 categorias, USDZ <3MB, 60fps/30fps, save <100ms, crash-free 99%, Actions <15min.
