# README-ASSETS — bundle e status de assets iOS

Fonte verdade: `catalog.json` (raiz) + `art-ios/*.glb` + `art-ios/*.usdz` + `art-source/*.blend`.
Padrão de conversão: `docs/PIPELINE.md` §3 e §6.

> Este arquivo registra o estado atual do pack e a validação restante em runtime/device.

## Estado atual (2026-10-13)

- `catalog.json`: **495 itens**, espelho de Resources validado pelo `check_catalog.py`.
- `art-ios/*.glb`: **495/495** presentes.
- `art-ios/*.usdz`: **495/495** convertidos e validados com OpenUSD 26.8 (`tools/convert_glb_usdz.py`).
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

1. Regenerar USDZ quando GLBs mudarem: `python3 -m pip install --user -r tools/requirements-usdz.txt && python3 tools/convert_glb_usdz.py --all`.
2. O `ios-app/project.yml` inclui `Resources/catalog.json`, `Resources/Sounds/`, `art-ios/` (GLB+USDZ) e `thumbnails/` no app bundle.
3. Incluir `thumbnails/*.png` no bundle se o catálogo visual do app usar os renders (resolver via `Catalog.thumbnailCandidates`).
4. Confirmar `AssetLoader` carrega um USDZ no simulador/device e que a unidade é 1 Blender unit = 1 metro.

`Resources/Sounds/` é processado pelo Swift Package (`Package.swift`) e usa `Bundle.module` em SwiftPM; o projeto XcodeGen copia a pasta para o app bundle. O workflow `ios-build` gera o `.xcodeproj` e compila o app para o SDK do Simulator.
