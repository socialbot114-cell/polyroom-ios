# Polyroom iOS — Cozy Low-Poly Decor (offline)

Jogo iPhone Swift, offline-first, estilo cozy: decorar 3 quartos low-poly livremente.
Referência arte: BlendSwap 24957 `Low-poly rooms` por `javiloz1604` (CC-BY, Blender 2.7x) — quarto / cozinha / sala.

## Stack
- iOS 17+, iPhone retrato, `SwiftUI + SceneKit`
- Save local `Codable JSON`, sem rede, sem login
- Arte: Blender 4.2 LTS -> USDZ + PNG thumbs
- CI: GitHub Actions (`macos-15` build iOS + `ubuntu` valida blend)

## Estrutura
```
polyroom/
  ios-app/        # projeto Xcode Polyroom (S2)
  art-source/     # .blend fonte (S1, nunca commitar .blend1)
  art-ios/        # .usdz + .scn otimizados p/ Xcode
  thumbnails/     # 256px png por item
  catalog.json    # catálogo único de itens (S3 valida)
  tools/          # check_blend.py, check_catalog.py
  docs/           # GDD, PIPELINE, ROADMAP, CONTRATOS
  prompts/        # tarefas S1/S2/S3
  .github/workflows/
```

## Sessões (orquestrador + 3 workers)
- Orquestrador: esta sessão — trava contratos, revisa, acompanha `TODO-ORQUESTRADOR.md`
- S1 Arte-Blender: `prompts/S1-ARTE.md`
- S2 iOS-Swift: `prompts/S2-IOS.md`
- S3 QA-CI: `prompts/S3-QA-CI.md`

## Quickstart
1. Ler `docs/CONTRATOS.md` e `docs/ROADMAP-30-DIAS.md`
2. S1 baixa referência, S2 cria projeto Xcode, S3 sobe CI
3. CI deve ficar verde antes de integrar USDZ real

## Licença arte
Derivado de CC-BY exige crédito em `Sobre`: "Baseado em Low-poly rooms por javiloz1604 (BlendSwap 24957), CC-BY".
