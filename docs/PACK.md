# PACK — o que shippa vs dev

- Ship no app (offline, ~11MB): `art-ios/*.glb` (8.5MB) + `thumbnails/*.png` (2.6MB) + `catalog.json`. Conversão `.usdz` no Mac via `tools/convert_glb_usdz_mac.sh`.
- Dev only (272MB, fora do bundle): `art-source/*.blend`. Material canônico em `art-source/_LIB_Polyroom_PBR.blend` (linkar em vez de duplicar).
- Cena total: 78k tris / 480 itens (média 162). Nenhum over 1200.
- CI rápida: `python3 tools/check_pack.py` (<5s, sem Blender). Full: `blender -b --python tools/check_blend.py` (~minutos, 480 arquivos).
