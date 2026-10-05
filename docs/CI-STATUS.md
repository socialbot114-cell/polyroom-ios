# CI-STATUS

Validação local D1:
- `python3 tools/check_catalog.py` -> 45 itens, 0 erros (WARNs de .usdz/.png ausentes OK até I1)
- `blender -b --python tools/check_blend.py` -> checked=1 errors=0 (cadeira 72 tris)

Ativação remota (S3 quando autorizado):
```bash
gh repo create polyroom-ios --private --source=. --push
git push -u origin main
gh run watch
```
Badges esperados no README futuro: `ios-build passing`, `assets-validate passing`. Tempo alvo <15min (Blender ~3min + Xcode ~8min).
