# PIPELINE Blender -> iOS

Blender validado: `4.2.1 LTS` em `/tmp/opencode/blender-4.2.1-linux-x64/blender`.

## 1. Baixar referência
```bash
# manual (login BlendSwap) ou colocar .blend em art-source/_ref/
# Arquivo: 24957 Low-poly rooms, CC-BY javiloz1604
```
Abrir em 4.2, `File > Append` por coleção se o arquivo 2.7 quebrar. Salvar como `art-source/REF_24957_converted.blend` (só ref, não shippa).

## 2. Limpar (S1, por quarto)
1. Separar `BED`, `KIT`, `LIV` em coleções
2. Remover câmeras/luzes Cycles, aplicar modifiers, `Merge by Distance`, recalc normals
3. Atlas UV: `Smart UV Project angle 66°`, pack 1024, bake base color se precisar
4. Aplicar transforms, origem na base, checar tris: `Statistics`
5. Salvar `art-source/BED_shell_v01.blend`, etc.

## 3. Export USDZ
No Blender: `File > Export > USD (.usd/.usdc)` com `Y-up`, depois converter:
```bash
# no Mac com Xcode:
xcrun usdz_converter art-ios/tmp.usdc art-ios/<id>.usdz
# fallback Linux: export .glb e S2 importa no Xcode que converte p/ .scn
```
Padrão MVP: exportar `.glb` + `.usdz` se possível, S2 escolhe o que liga no `scnassets`.

## 4. Thumbnail (geometria real)
```bash
python3 tools/render_catalog_thumbnails.py --sample
python3 tools/render_catalog_thumbnails.py --ids bed_moveis_cama_casal,liv_moveis_sofa
python3 tools/render_catalog_thumbnails.py --all --workers 2 --samples 64
python3 tools/render_catalog_thumbnails.py --verify
```
Gera 256×256 opaco, enquadramento automático por bounding box, fundo cozy,
estúdio 3-point e override por categoria apenas para materiais planos.
Detalhes e exemplo de amostra: `docs/THUMBNAILS.md`.

## 5. Validação CI
`tools/check_blend.py` roda `--background`: abre cada `.blend`, conta tris, checa nomes, UVs, tamanho. Falha se > budget em CONTRATOS.
`tools/check_catalog.py` valida schema, espelho Resources, USDZ (WARN enquanto a conversão Mac estiver pendente) e thumbnails. Rodar também `tools/check_pack.py`, `tools/check_scale.py` e `tools/check_kill_restore.py`.

## 6. Integração no Xcode (S2)
Arrastar `art-ios/*.usdz` para `ios-app/Polyroom/Resources/`, `Copy Bundle Resources`, carregar via `SCNScene(named:)`, cache em `AssetLoader`.
