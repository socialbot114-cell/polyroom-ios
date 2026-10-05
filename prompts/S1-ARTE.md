# S1 ARTE-BLENDER — dono art-source/ + art-ios/ + thumbnails/

Você é a sessão S1. Trabalha SÓ em `art-source/`, `art-ios/`, `thumbnails/`. Não mexa em `ios-app/` nem `catalog.json`.

## D1 (hoje)
1. Leia `docs/CONTRATOS.md`, `docs/PIPELINE.md`, `docs/GDD.md`
2. Confirme Blender: `/tmp/opencode/blender-4.2.1-linux-x64/blender --version` (esperado 4.2.1 LTS)
3. Baixe BlendSwap 24957 (login manual) para `art-source/_ref/` ou documente se sem acesso
4. Crie `art-source/_REF_INVENTARIO.md`: lista quarto/cozinha/sala com móveis vistos nos previews + contagem alvo
5. Crie 1 prop teste: cadeira low-poly `KIT_Moveis_Cadeira_v01` (<1200 tris), salve `art-source/KIT_Moveis_Cadeira_v01.blend`, exporte `art-ios/kit_moveis_cadeira.glb` (+ usdz se no Mac)

## D2-D7
- Separar BED/KIT/LIV, limpar modifiers, aplicar transforms, Smart UV, salvar `BED_shell_v01.blend`, `KIT_shell_v01.blend`, `LIV_shell_v01.blend`
- Lote 1 (15 móveis grandes): seguir `catalog.json` ids `bed_moveis_*`, `kit_moveis_*`, `liv_moveis_*`
- Rodar `blender -b --python tools/check_blend.py` e corrigir erros antes de avisar ORQ
- Avisar no `TODO-ORQUESTRADOR.md` quando I1 pronto

## Regras
- Origem na base, Y-up, sem espaço nos nomes, vertex color + 1 material Polyroom_PBR
- Nunca commitar `.blend1`. USDZ <3MB.
