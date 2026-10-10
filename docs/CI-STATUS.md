# CI-STATUS

Validação local D1:
- `python3 tools/check_catalog.py` -> 45 itens, 0 erros (WARNs de .usdz/.png ausentes OK até I1)
- `blender -b --python tools/check_blend.py` -> checked=1 errors=0 (cadeira 72 tris)

> Estado 2026-10-06: esperado atualizado para 480 itens (não 45). `check_catalog.py` deve reportar `itens=480 erros=0` (WARNs `.usdz` 0/480 OK até conversão Mac). `check_blend.py` existência: 481 `.blend`. Matriz/gates antigos de 45 obsoletos.
>
> Estado 2026-10-10: gate local verde — `check_catalog` 480/0 (normal e `STRICT=1`), `check_pack` 480/0/0, `demo_load` 9/0, `check_blend` 481/0; thumbnails reais 480/480 (`docs/THUMBNAILS.md`); `previews/contact-sheet-480.png` + 15 sheets + `relatorio-480.md` regenerados (`thumbs_problema=0`). Pendente Mac: `.usdz` 0/480, xcodeproj, FPS device.

Ativação remota (S3 quando autorizado):
```bash
gh repo create polyroom-ios --private --source=. --push
git push -u origin main
gh run watch
```
Badges esperados no README futuro: `ios-build passing`, `assets-validate passing`. Tempo alvo <15min (Blender ~3min + Xcode ~8min).
