# PACK — o que shippa vs dev

- Ship no app (offline, ~11MB): `art-ios/*.glb` (8.5MB) + `thumbnails/*.png` (2.6MB) + `catalog.json`. Conversão `.usdz` no Mac via `tools/convert_glb_usdz_mac.sh`.
- Dev only (272MB, fora do bundle): `art-source/*.blend`. Material canônico em `art-source/_LIB_Polyroom_PBR.blend` (linkar em vez de duplicar).
- Cena total: 78k tris / 480 itens (média 162). Nenhum over 1200.
- Cena real (2026-10-10, base `tris` do catalog = teto conservador):
  demo_save 9 itens = 12.6k + 3 shells (108) = 12.7k;
  I1 pior caso (16 maiores + shells) = 30k < 50k ✅; I2 típico (35×~300) ≈ 10.6k.
  Geometria real dos GLBs ≈ ⅓ do declarado (amostra 40: 9.1k reais vs 27.9k;
  demo_save real = 7.9k) — margem extra folgada.
- CI rápida: `python3 tools/check_pack.py` (<5s, sem Blender). Full: `blender -b --python tools/check_blend.py` (~minutos, 480 arquivos).
