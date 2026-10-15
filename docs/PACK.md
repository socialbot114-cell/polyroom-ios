# PACK — o que shippa vs dev

- Fonte do bundle (offline): `art-ios/*.glb` (495 itens, 10.57MB) + `art-ios/*.usdz` (495, 8.46MB) + `thumbnails/*.png` (495, 14.77MB, paleta 256 cores) + `catalog.json`; o espelho iOS fica em `ios-app/Polyroom/Resources/catalog.json`.
- Dev only (278.6MB, fora do bundle): `art-source/*.blend`. Material canônico em `art-source/_LIB_Polyroom_PBR.blend` (linkar em vez de duplicar).
- Catálogo: 495 GLBs. `tris` declarado soma 276,298 (teto conservador); geometria GLB real fica abaixo desse valor. Todos os assets seguem abaixo do limite de 3000 tris por prop.
- Cena real (2026-10-13, base `tris` do catalog = teto conservador):
  demo_save 9 itens = 12.6k + 3 shells (108) = 12.7k;
  I1 pior caso (16 maiores + shells) = 30k < 50k ✅; I2 típico (35×~300) ≈ 10.6k.
  Geometria real dos GLBs ≈ ⅓ do declarado (amostra 40: 9.1k reais vs 27.9k;
  demo_save real = 7.9k) — margem extra folgada.
- CI rápida: `python3 tools/check_pack.py` (<5s, sem Blender). Full: `blender -b --python tools/check_blend.py` (~minutos, blends de origem).
- Sons: `Resources/Sounds/*.wav` (6 arquivos, ~118KB), processados pelo Swift Package.
- iOS CI: `swift test --package-path ios-app/Polyroom` + XcodeGen project + app build para o iOS Simulator SDK em todo push. O runner não conecta ao CoreSimulator; Archive/TestFlight e FPS físico continuam gates de device.
