# README-ASSETS — bundle e status de assets iOS

Fonte verdade: `catalog.json` (raiz) + `art-ios/*.glb` (atual) + `art-source/*.blend`.
Padrão de conversão: `docs/PIPELINE.md` §3 e §6.

> Este arquivo registra o estado atual do pack e os passos restantes no Mac.

## Estado atual (2026-10-13)

- `catalog.json`: **495 itens**, espelho de Resources validado pelo `check_catalog.py`.
- `art-ios/*.glb`: **495/495** presentes; 0 `.usdz` até conversão no Mac.
- `thumbnails/*.png`: **495/495 renders reais 256×256**, `docs/THUMBNAILS.md`.
- `art-source/*.blend`: modelo fonte para cada item criado localmente; `check_blend.py` é o gate integral.
- Matriz 3 salas × 15 categorias: **todas as 45 células têm ≥4 opções**.

## Regenerar thumbnails

```bash
python3 tools/render_catalog_thumbnails.py --all --workers 2 --samples 64
python3 tools/make_contact_sheet.py --per-category
python3 tools/check_catalog.py
python3 tools/check_pack.py
```

## Integração Xcode (S2)

1. No Mac, converter GLB→USDZ com `bash tools/convert_glb_usdz_mac.sh` e validar `ALLOW_MISSING=0 python3 tools/check_catalog.py`.
2. Incluir `Resources/catalog.json`, `Resources/Sounds/` e os USDZ no `Copy Bundle Resources` do app target.
3. Incluir `thumbnails/*.png` no bundle se o catálogo visual do app usar os renders (resolver via `Catalog.thumbnailCandidates`).
4. Confirmar `AssetLoader` carrega um USDZ no simulador/device e que a unidade é 1 Blender unit = 1 metro.

`Resources/Sounds/` é processado pelo Swift Package (`Package.swift`) e usa `Bundle.module` em SwiftPM; no Xcode, mantenha a pasta em recursos do app. O workflow `ios-build` agora roda `swift test` mesmo antes da criação do `.xcodeproj`.
