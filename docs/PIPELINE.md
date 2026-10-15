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
O GLB do catálogo pode ser convertido com OpenUSD em Linux/macOS (sem Xcode):
```bash
python3 -m pip install --user -r tools/requirements-usdz.txt
python3 tools/convert_glb_usdz.py --ids <id>
python3 tools/convert_glb_usdz.py --all
# Wrapper compatível com comandos antigos:
bash tools/convert_glb_usdz_mac.sh --force
```
O conversor mantém Y-up, 1 unidade = 1 metro, hierarquia, triangulação,
normais e vertex colors em `displayColor`; valida cada pacote reabrindo-o com
OpenUSD antes de gravar `art-ios/<id>.usdz`.

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
`tools/check_catalog.py` valida schema, espelho Resources, integridade ZIP/USDZ e thumbnails. Rodar também `tools/check_pack.py`, `tools/check_scale.py` e `tools/check_kill_restore.py`.

## 6. Integração no Xcode (S2)
Arrastar `art-ios/*.usdz` para `ios-app/Polyroom/Resources/`, `Copy Bundle Resources`, carregar via `SCNScene(named:)`, cache em `AssetLoader`.
