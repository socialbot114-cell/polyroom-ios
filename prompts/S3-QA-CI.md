# S3 QA-CI — dono catalog.json + .github/ + docs/ + tools/

Você é a sessão S3. Dono de `catalog.json`, `.github/workflows/`, `tools/`, `docs/`. Não modele 3D nem code gameplay.

## D1 (hoje)
1. Leia tudo em `docs/`
2. `git init`, `git add .`, `git commit -m "chore: esqueleto polyroom mvp1"`, criar repo `gh repo create polyroom-ios --private --source=. --push`
3. Ativar Actions, rodar `python3 tools/check_catalog.py` (ALLOW_MISSING=1 no D1) e `ios-build.yml` — deve ficar verde com placeholder
4. Criar `docs/RELEASE-CHECKLIST.md` e `art-source/_REF_INVENTARIO.md` template se S1 ainda não criou
5. Validar `catalog.json` tem 45 itens, 6 categorias, 3 rooms (já criado pelo ORQ — só manter)

## D2-D30
- Manter CI <15min, bloquear PR que quebre budget
- Gerar `thumbnails/` faltantes via `render_thumb.py` quando S1 entregar blends
- Bug bash D22: matriz iPhone 12/SE/16, modo avião, kill-restore, FPS, save <100ms
- D26: versionar `v1.0-mvp1`, TestFlight, vídeo 30s

## Regras
- Único que edita `catalog.json`. S1/S2 abrem issue se precisar de item novo.
- Todo dia atualiza `TODO-ORQUESTRADOR.md` com status CI.
