# BUG-BASH v1.0-mvp1 — 20 casos de teste

Data: 2026-10-05. Escopo: `RELEASE-CHECKLIST.md` + `catalog.json` (45 itens) + `demo_save_v1.json`.
Como rodar validações locais antes do bash:
```bash
python3 tools/check_catalog.py        # esperado: itens=45 erros=0 (WARNs .usdz OK até I1)
python3 tools/demo_load.py            # esperado: itens=9 erros=0 warns=0
python3 tools/check_blend.py          # fora do Blender: só existência (blender ausente = gap BB-20)
ALLOW_MISSING=0 python3 tools/check_catalog.py  # esperado v1.0: 0 erros (hoje falha: 45 .usdz ausentes)
```
Estado atual dos assets (2026-10-05): `.blend=44/45`, `.glb=44/45`, `.png=45/45`, `.usdz=0/45`.
ID sem `.glb`: `bed_moveis_cadeira` (tem `.png`, sem `.blend` fonte e sem `.glb`; shells OK — hipótese "shell?" refutada).
IDs sem `.usdz`: 45/45 (todos).

Legenda severidade: `BLOQ` = bloqueia v1.0 · `ALTA` = deve corrigir antes da tag · `MEDIA` = aceitável com nota de release.

---

## BB-01 — Save kill-restore (3 rooms, 9 itens) [ALTA]
Checklist: save/load após kill (`polyroom_save_v1.json`, <100ms).
1. Abrir app, colocar 3 itens no quarto + 3 cozinha + 3 sala (ex. os 9 de `demo_save_v1.json`), mover/rotar/pintar alguns.
2. Background + kill via app switcher (não só home).
3. Reabrir app.
Esperado: 9 itens nas posições/cores/rotação exatas, `coins` preservado, load <100ms, sem tela vazia. Falha se: sala vazia, posição resetada, crash no launch.

## BB-02 — Save corrupto recupera com save vazio [ALTA]
Checklist: save corrupto recupera com save vazio.
1. Com app fechado, abrir `Documents/polyroom_save_v1.json` (Files/Simulator) e truncar para `{xxx` ou apagar metade.
2. Abrir app.
Esperado: app abre sem crash, cai para `RoomSave()` vazio (3 rooms vazias, coins 70 — ver `SaveManager.load()`), log/console sem exception. Falha se: crash, tela preta, loop.

## BB-03 — Modo avião 100% funcional [ALTA]
Checklist: modo avião, sem `URLSession`.
1. Ativar modo avião + Wi-Fi off.
2. Fazer loop completo: trocar BED/KIT/LIV, colocar 1 item de cada categoria, mover, girar, pintar, duplicar, excluir, snapshot.
3. Grep estático: `grep -rn URLSession ios-app` deve retornar vazio (hoje só há `URL(fileURLWithPath:)` em teste — OK).
Esperado: zero spinner de rede, zero erro de conexão, tudo local. Falha se: qualquer request, thumb remota, analytics.

## BB-04 — Snap 0.25m + clamp 6x6 ([-3,3]) [ALTA]
Checklist: 45 SKUs colocáveis; regras `Snap.swift` + `demo_load.py`.
1. Arrastar item para x=1.13, z=-2.87 (fora do grid).
2. Arrastar item para borda e tentar soltar em x=5, z=5.
3. Rodar `python3 tools/demo_load.py` com save editado fora do snap (ex. x=0.13) — deve dar WARN, não ERROR.
Esperado: (1) arredonda para 1.25 / -2.75 (`snapClamp`); (2) clampea em ±3.0; (3) `demo_load` WARN "fora do snap 0.25". Falha se: item flutua entre grid, sai do piso 6x6, z-fight na parede.

## BB-05 — Girar 45° com wrap 360→0 [MEDIA]
Checklist: girar 45°.
1. Selecionar item, tocar girar 8x (8×45=360).
2. Girar 1x anti-horário (-45) a partir de 0.
3. Checar `RoomStore.rotate(id:step:)` normaliza para [0,360), sem -0.0.
Esperado: após 8 giros volta a 0 (não 360); de 0 volta para 315. `demo_load` com rotationY=30 deve WARN "nao multiplo de 45". Falha se: acumula 360/405, -45, -0.0 no JSON.

## BB-06 — Duplicar com offset +0.25 e novo UUID [MEDIA]
Checklist: inspector duplicar.
1. Selecionar item em x=2.9 (perto da borda), tocar Duplicar.
2. Abrir save e comparar `id`s.
3. Duplicar item com `colorIndex=3` e `rotationY=90`.
Esperado: cópia em x+0.25 com clamp (2.9→3.0, não 3.15), mesmo catalogId/room/cor/rotação, `id` UUID novo e único, cópia selecionada. Falha se: UUID duplicado, cópia fora do quarto, cor resetada.

## BB-07 — Cor tintable: 6 swatches vs não-tintable [MEDIA]
Checklist: recolor; `docs/CORES-PALETA.md` (29 tintable=true, 16 false; shells sempre false).
1. Abrir item `tintable:true` (ex. `bed_moveis_cama_casal`) → aplicar os 6 swatches (#C9A87A…#6C584C).
2. Abrir shell (`shell_quarto`) e eletro `kit_moveis_fogao` (`tintable:false`) → tentar pintar.
3. `setColor(id:index:)` com index -1 e 99.
Esperado: (1) base color troca e persiste; (2) shells/eletros ignoram tint (cor bakeada); (3) index<0 clampa para ≥0. Falha se: shell tinte, crash com index inválido, cor não salva.

## BB-08 — 60fps iPhone 12 / 30fps SE2, cena <50k tris [BLOQ]
Checklist: FPS + tris.
1. Montar cena cheia: 3 shells (~4k tris cada) + 9–12 props (pior caso ~25k) e medir com Instruments/CoreAnimation FPS em iPhone 12 e SE2 (ou Simulator + device real se houver).
2. Somar `tris` do `catalog.json` da cena.
Esperado: ≥60fps iPhone 12, ≥30fps SE2, cena <50k tris, sem jank no orbit/pinch. Falha se: drop sustentado, aquecimento, tris estourado. Hoje: NUNCA MEDIDO — gap.

## BB-09 — Thumb faltando → placeholder, sem crash [MEDIA]
Checklist: thumbs 256px; hoje 45/45 OK, mas testar regressão.
1. Renomear temporariamente `thumbnails/liv_moveis_tv.png` e abrir catálogo na categoria `moveis`/sala.
2. Restaurar arquivo.
Esperado: card mostra placeholder (fundo #B08968 + inicial, ver `README-ASSETS.md`), sem crash, sem célula vazia. `check_catalog.py` com `ALLOW_MISSING=1` dá WARN; com `0` dá ERROR. Falha se: crash, lista trava, imagem esticada.

## BB-10 — USDZ faltando → fallback teal box, sem crash [BLOQ até conversão Mac]
Checklist: 45 SKUs colocáveis; `AssetLoader.load(catalogId:)` tenta `<id>.usdz`, senão `SCNBox` teal 0.4m.
1. Colocar os 45 ids (todos sem `.usdz` hoje) um por vez.
2. Confirmar que cada um renderiza a caixa teal 0.4m e continua selecionável/movível.
Esperado: nenhum crash, nenhum item invisível; fallback consistente. Falha se: crash no `SCNScene(named:)`, item some, escala errada. Nota: em v1.0 real todos devem carregar `.usdz` (<3MB/item, shell <8MB) — hoje 0/45 existem.

## BB-11 — 3 shells trocáveis sem reload [ALTA]
Checklist: BED/KIT/LIV sem reload.
1. Colocar 3 itens no quarto, trocar para cozinha, voltar ao quarto.
2. Trocar de shell 10x rápido.
Esperado: itens de cada room preservados (`RoomStore.switchRoom` limpa só seleção), sem reload de cena, sem leak, sem itens "vazando" entre rooms. Falha se: itens somem, duplicam, app trava.

## BB-12 — Catálogo: 45 itens, busca + filtro por categoria [ALTA]
Checklist: 45 SKUs, 6 categorias com ≥4 opções/quarto.
1. Contar cards no app vs `catalog.json` (45).
2. Filtrar cada categoria em cada quarto; buscar "cadeira", "tapete".
3. Cruzar com matriz real (2026-10-05): só 4/18 combos quarto×categoria têm ≥4 (quarto-moveis 8, cozinha-moveis 7, cozinha-acessorios 4, sala-moveis 8, sala-acessorios 5 — resto <4).
Esperado: 45 cards com thumb 64px, busca/filtro funcionam. Falha (CONTEÚDO): 13/18 combos <4 — documentado como gap v1.0, não bug de UI.

## BB-13 — Snapshot PNG + share local (offline) [MEDIA]
Checklist: snapshot + share.
1. Montar sala, tocar botão câmera, salvar PNG.
2. Compartilhar via share sheet com avião ligado.
Esperado: PNG salvo local, share abre sem rede. Falha se: botão ausente (hoje NÃO IMPLEMENTADO no Swift — gap), permissão de Fotos negada trava, PNG preto.
Estado 2026-10-06: IMPLEMENTADO em `ios-app/Polyroom/Sources/Views/ContentView.swift` (`takeSnapshot` + `renderPhoto` + `savePNGToDocuments`, AboutView incluso) — falta só teste em device.

## BB-14 — Onboarding 3 passos + Sobre CC-BY [MEDIA]
Checklist: onboarding + "Baseado em Low-poly rooms por javiloz1604 (BlendSwap 24957), CC-BY".
1. Fresh install → verificar 3 cards de onboarding.
2. Abrir Sobre → procurar crédito exato.
Esperado: 3 passos puláveis, crédito literal presente. Falha se: ausente (hoje NÃO IMPLEMENTADO — gap), texto diferente, sem atribuição (viola CC-BY).
Estado 2026-10-06: PARCIAL — `AboutView` existe em `ContentView.swift` (crédito CC-BY literal OK) + `OnboardingView.swift` existe (3 cards: quarto/arrastar/offline, `hasSeenOnboarding`) — falta só teste em device/fresh install.

## BB-15 — Ícone 1024, splash, version 1.0(1), portrait, iOS 17+ [BLOQ]
Checklist: ícone/splash/version.
1. Verificar `AppIcon` 1024, `LaunchScreen`, `Info.plist` (`CFBundleShortVersionString=1.0`, `CFBundleVersion=1`), `UISupportedInterfaceOrientations=portrait`, `MinimumOSVersion=17`.
2. Instalar em device iOS 17 e tentar em iOS 16 (deve recusar).
Esperado: tudo presente. Falha se: ausente (hoje SEM xcodeproj/xcassets/Info.plist — gap BLOQ), landscape permitido, roda em iOS 16.

## BB-16 — Monkey 15min sem crash [ALTA]
Checklist: sem crash em 15min monkey.
1. Rodar 15min de taps/drags/rotate/duplicar/excluir/trocar room aleatórios (manual ou `xcodebuild test` + script).
2. Checar memory/CPU.
Esperado: zero crash, zero leak grave, autosave íntegro ao final. Falha se: qualquer crash, save zerado. Hoje: NUNCA RODADO — gap.

## BB-17 — Colocar/remover/excluir e seleção [MEDIA]
1. Tap item no catálogo → aparece no centro (0,0) selecionado.
2. Lixeira/excluir → seleção limpa, item some do save.
3. Tocar no vazio → desseleciona.
Esperado: `place` seleciona novo item; `remove` limpa `selectedId` se era o selecionado; sem "fantasma" selecionado. Falha se: seleção presa, excluir errado, item órfão no JSON.

## BB-18 — Limites: fora 6x6, colorIndex, UUID, rooms inválidas [MEDIA]
1. Editar save: x=99, rotationY=30, colorIndex=99, room="banheiro", id duplicado, catalogId inexistente → rodar `python3 tools/demo_load.py`.
Esperado: ERROR em version/rooms/coins, x fora [-3,3], id não-UUID/duplicado, catalogId inexistente, room inválida; WARN em snap/rotation/colorIndex>5/compat room×catalog.rooms. Falha se: `demo_load` dá exit 0 com save inválido (hoje: demo oficial dá `itens=9 erros=0 warns=0` — OK).

## BB-19 — CI verde: `assets-validate` + `ios-build` [BLOQ]
1. `gh run watch` após push: `assets-validate` (Blender 4.2 check_blend + check_catalog) e `ios-build` (macos-15, iPhone 16 sim, `CODE_SIGNING_ALLOWED=NO`) verdes, <15min.
2. `ALLOW_MISSING=0 python3 tools/check_catalog.py` deve ser 0 erros (hoje: 45 erros — gap).
Esperado: badges `passing` no README. Falha se: qualquer job vermelho; hoje build é placeholder sem xcodeproj ("WARN: Xcodeproj ainda nao criado") e push remoto aguarda autorização (`gh repo create polyroom-ios --private`).

## BB-20 — Blender full check (tris/UV/nomes) + higiene `.blend1` [ALTA]
1. Em máquina com Blender 4.2.1: `blender -b --python tools/check_blend.py` → esperado `checked=44 errors=0` (+1 quando `BED_Moveis_Cadeira` for modelado).
2. Verificar: sem espaço/acento nos nomes, tris ≤3000/prop e ≤15000/shell, com UVs; USDZ <3MB, shell <8MB.
3. Apagar `art-source/KIT_Moveis_Cadeira_v01.blend1` (higiene; está gitignored mas viola `CONTRATOS.md` §7).
Esperado: 0 ERROR. Falha se: overbudget, sem UV, nome inválido. Hoje: Blender ausente neste host (`NO_BLENDER`) — só rodou modo existência (`encontrados: 44`).
