# README-ASSETS — Mapeamento GLB atual → USDZ futuro

Fonte verdade: `catalog.json` (raiz) + `art-ios/*.glb` (atual) + `art-source/*.blend`.
Padrão de conversão: `docs/PIPELINE.md` §3 e §6.

> Este arquivo vive em `ios-app/Polyroom/Resources/` para o S2 saber o que arrastar
> para o Xcode (`Copy Bundle Resources`, `SCNScene(named:)`, cache em `AssetLoader`).
> Não altera gameplay — só inventário de assets.

## Lote placeholder D1 — 13 ids (enunciado diz 12, lista contém 13)

| id | nome | .glb atual (`art-ios/`) | .usdz futuro (`art-ios/`) | thumb (`thumbnails/`) | status |
|----|------|--------------------------|----------------------------|------------------------|--------|
| `shell_quarto` | Shell Quarto | `art-ios/shell_quarto.glb` ✅ existe | `art-ios/shell_quarto.usdz` ⏳ pendente | `thumbnails/shell_quarto.png` ✅ placeholder 256px | .blend: `art-source/BED_shell_v01.blend` |
| `shell_cozinha` | Shell Cozinha | `art-ios/shell_cozinha.glb` ✅ existe | `art-ios/shell_cozinha.usdz` ⏳ pendente | `thumbnails/shell_cozinha.png` ✅ placeholder 256px | .blend: `art-source/KIT_shell_v01.blend` |
| `shell_sala` | Shell Sala | `art-ios/shell_sala.glb` ✅ existe | `art-ios/shell_sala.usdz` ⏳ pendente | `thumbnails/shell_sala.png` ✅ placeholder 256px | .blend: `art-source/LIV_shell_v01.blend` |
| `kit_moveis_cadeira` | Cadeira Cozinha | `art-ios/kit_moveis_cadeira.glb` ✅ existe | `art-ios/kit_moveis_cadeira.usdz` ⏳ pendente | `thumbnails/kit_moveis_cadeira.png` ✅ placeholder 256px | .blend: `art-source/KIT_Moveis_Cadeira_v01.blend` |
| `bed_moveis_cama_casal` | Cama Casal | `art-ios/bed_moveis_cama_casal.glb` ✅ existe | `art-ios/bed_moveis_cama_casal.usdz` ⏳ pendente | `thumbnails/bed_moveis_cama_casal.png` ✅ placeholder 256px | .blend: `art-source/BED_Moveis_CamaCasal_v01.blend` |
| `bed_moveis_guarda_roupa` | Guarda-roupa | `art-ios/bed_moveis_guarda_roupa.glb` ✅ existe | `art-ios/bed_moveis_guarda_roupa.usdz` ⏳ pendente | `thumbnails/bed_moveis_guarda_roupa.png` ✅ placeholder 256px | .blend: `art-source/BED_Moveis_GuardaRoupa_v01.blend` |
| `bed_moveis_criado` | Criado-mudo | `art-ios/bed_moveis_criado.glb` ✅ existe | `art-ios/bed_moveis_criado.usdz` ⏳ pendente | `thumbnails/bed_moveis_criado.png` ✅ placeholder 256px | .blend: `art-source/BED_Moveis_Criado_v01.blend` |
| `kit_moveis_bancada` | Bancada Cozinha | `art-ios/kit_moveis_bancada.glb` ✅ existe | `art-ios/kit_moveis_bancada.usdz` ⏳ pendente | `thumbnails/kit_moveis_bancada.png` ✅ placeholder 256px | .blend: `art-source/KIT_Moveis_Bancada_v01.blend` |
| `kit_moveis_geladeira` | Geladeira | `art-ios/kit_moveis_geladeira.glb` ✅ existe | `art-ios/kit_moveis_geladeira.usdz` ⏳ pendente | `thumbnails/kit_moveis_geladeira.png` ✅ placeholder 256px | .blend: `art-source/KIT_Moveis_Geladeira_v01.blend` |
| `kit_moveis_mesa` | Mesa Cozinha | `art-ios/kit_moveis_mesa.glb` ✅ existe | `art-ios/kit_moveis_mesa.usdz` ⏳ pendente | `thumbnails/kit_moveis_mesa.png` ✅ placeholder 256px | .blend: `art-source/KIT_Moveis_Mesa_v01.blend` |
| `liv_moveis_sofa` | Sofa 2 Lugares | `art-ios/liv_moveis_sofa.glb` ✅ existe | `art-ios/liv_moveis_sofa.usdz` ⏳ pendente | `thumbnails/liv_moveis_sofa.png` ✅ placeholder 256px | .blend: `art-source/LIV_Moveis_Sofa_v01.blend` |
| `liv_moveis_rack` | Rack TV | `art-ios/liv_moveis_rack.glb` ✅ existe | `art-ios/liv_moveis_rack.usdz` ⏳ pendente | `thumbnails/liv_moveis_rack.png` ✅ placeholder 256px | .blend: `art-source/LIV_Moveis_Rack_v01.blend` |
| `liv_moveis_estante` | Estante | `art-ios/liv_moveis_estante.glb` ✅ existe | `art-ios/liv_moveis_estante.usdz` ⏳ pendente | `thumbnails/liv_moveis_estante.png` ✅ placeholder 256px | .blend: `art-source/LIV_Moveis_Estante_v01.blend` |

Legenda: ✅ existe no repo · ⏳ pendente (CI `check_catalog.py` emite WARN com `ALLOW_MISSING=1`, erro com `ALLOW_MISSING=0`).

## Como gerar o faltante (resumo PIPELINE)

```bash
# 1. Modelar em art-source/<ID>_v01.blend (origem na base, Smart UV, Polyroom_PBR)
# 2. Export .glb (fallback Linux) + .usdz no Mac:
xcrun usdz_converter art-ios/tmp.usdc art-ios/<id>.usdz
# 3. Thumb final 256px transparente (substitui placeholder PIL):
blender -b art-source/<ID>_v01.blend -o thumbnails/<id>_ --python tools/render_thumb.py -f 1
# 4. Validar:
python3 tools/check_catalog.py
```

## Integração Xcode (S2)

1. Arrastar `art-ios/*.usdz` (quando existirem; hoje só `.glb`) para `ios-app/Polyroom/Resources/` no Xcode, marcar `Copy Bundle Resources`.
2. `catalog.json` espelho em `ios-app/Polyroom/Resources/catalog.json` — manter sincronizado com raiz.
3. Carregar via `SCNScene(named: "<id>.usdz")` com cache em `Sources/Scene/AssetLoader.swift`.
4. Thumbs lidos de `thumbnails/<id>.png` (placeholder atual: fundo `#B08968` categoria `moveis` + inicial do nome, 256×256 RGBA).

## Notas

- `usdz` em `catalog.json` aponta para `art-ios/<id>.usdz` para todos os 45 itens; nenhum `.usdz` existe ainda — conversão é D2 (ver `tools/check_catalog.py` WARNs).
- Thumbs deste lote são placeholders PIL — CI D1 só checa existência (`os.path.exists`), não conteúdo.
- Não modelar 3D aqui; não editar gameplay / `Sources/`.
