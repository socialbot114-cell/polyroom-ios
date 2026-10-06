# PLANO 300% — Polyroom (3 terminais)

Meta: 3x em visual + gameplay + performance. Eu (130740 pts/1) orquestro + integro.
Agentes via arquivos + `git pull` + aviso no pts. Sem digitar no terminal alheio.

## AGENTE-A (pts/5, PID 134247) — Arte final
Dono: `art-source/`, `art-ios/`, `thumbnails/`, `previews/`.
1. `git pull` e ler `docs/PACK.md`, `docs/CORES-PALETA.md`
2. T1: bevel leve nos 410 restantes sem bevel (só `moveis` feito) — script como `/tmp/bevel_moveis.py`, 1 seg, re-export `.glb`, `check_blend` 0 errors
3. T2: 15 thumbs reais hero (cama, sofá, lustre, geladeira duplex, tenda) com 3-point + fundo cozy opaco — substituir PIL só dessas
4. T3: 3 previews signer (quarto feito, sala vivida, cozinha equipada) em `previews/`
5. Commit por tarefa, nunca tocar `ios-app/` nem `catalog.json`

## AGENTE-B (pts/2, PID 201399) — Gameplay offline
Dono: `ios-app/` (menos `Resources/catalog.json` que é espelho).
1. `git pull` e ler `ios-app/README.md`, `Sources/Scene/RoomStore.swift`
2. T1: `Missions.swift` — 12 missões cozy (ex "coloque 5 móveis na sala", "use 3 plantas", "tire 2 fotos") com progresso + recompensa coins, tudo local
3. T2: `Inspector` parede/piso + altura (usa `setMount` já pronto) + busca no `CatalogView` por nome/tag
4. T3: `snapshot` share + `Onboarding` 2.0 com os prints novos
5. `swift test` lógica onde der; nunca tocar `art-source/` nem raiz `catalog.json`

## EU (orquestrador) — integração
- Travo contratos, resolvo conflito, rodo `check_blend/check_pack/check_catalog/demo_load`
- QA semanal `docs/BUG-BASH.md`, `TODO-ORQUESTRADOR.md` atualizado, tag `v1.0` no Mac
- Regra: PR pequeno, CI verde, sem push `--force`

## Gates 300%
- G1: bevel 480/0 errors + glb <15MB
- G2: 15 thumbs reais + 3 previews signer
- G3: 12 missões + busca + snapshot funcionando (lógica testada)
- G4: save <100ms, cena <80k tris, crash-free
