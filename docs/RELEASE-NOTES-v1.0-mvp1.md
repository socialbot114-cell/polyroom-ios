# RELEASE-NOTES v1.0-mvp1 (MVP-1)

Data: 2026-10-05 · Tag alvo: `v1.0-mvp1` · Version: 1.0 (build 1) · iOS 17+, iPhone portrait, 100% offline.

> Estado real nesta data: arte `.glb` 44/45 + thumbs 45/45, `.usdz` 0/45 (conversão no Mac pendente).
> Estes notes descrevem o MVP-1 pretendido + limitações conhecidas. Não shippar como final até os gaps em `docs/BUG-BASH.md` (BB-08/BB-10/BB-15/BB-19) fecharem.
> Nota 2026-10-06 (sem reescrever release): catalog 480, usdz 0/480, glb 480/480, blends 481. Snapshot + Sobre/Onboarding implementados em `ContentView.swift`/`OnboardingView.swift` (falta só teste device). Matriz 45 obsoleta — ver `docs/GAPS-V1.1.md`.

## Conteúdo MVP-1
- 3 quartos diorama 6x6m (piso + 2 paredes h=3m, origem no centro): quarto (BED), cozinha (KIT), sala (LIV). Troca de shell sem reload.
- 45 SKUs em `catalog.json` v1, 6 categorias: `moveis` (20), `acessorios` (9), `sub_itens` (5), `texteis` (5), `iluminacao` (3), `plantas` (3). Cada item: `footprint` S/M/L, `tintable` bool (29 sim / 16 não — shells sempre não), `tris`, `tags`, `thumb` 256px.
- Catálogo bottom-sheet com busca + filtro por categoria, cards com thumb.
- Save local `Documents/polyroom_save_v1.json` (`RoomSave` Codable v1, `coins` inicial 70): autosave a cada mutação (<100ms), restore após kill, save corrupto cai para save vazio sem crash.
- Moedas locais `cozyCoins` (UserDefaults, sem servidor): checklist por quarto, fotos, abrir 3 dias; 2º/3º quarto desbloqueiam com 20/50 coins.
- Onboarding 3 cards + tela Sobre com crédito CC-BY + snapshot PNG com share local (ver docs `GDD.md`, `ROADMAP-30-DIAS.md` D15–D17/D26–D27).

## Controles
- Escolher quarto (Bed/Kit/Liv) → aba categoria → tap no item → aparece no centro → arrastar para mover (snap 0.25m, clamp ±3m).
- Inspector flutuante: mover · girar 45° (wrap 360→0) · cor 6 swatches (só se `tintable:true` + material `Polyroom_PBR`) · duplicar (+0.25m em x, novo UUID) · excluir.
- Câmera isométrica fofa: ortho ~35°, orbit 1 dedo yaw ±60° + pitch 30–60°, pinch 0.7–1.8x, double-tap reset. Sombra suave baked + 1 directional realtime.
- Paleta cozy (ver `docs/CORES-PALETA.md`): `#C9A87A` Madeira Clara · `#D08C60` Terracota · `#F1E3D3` Creme Baunilha · `#8FA98F` Verde Sálvia · `#A3B8CC` Azul Névoa · `#6C584C` Grafite Quente.

## Créditos CC-BY (obrigatório na tela Sobre)
```
Baseado em Low-poly rooms por javiloz1604 (BlendSwap 24957), CC-BY
```
Referência: BlendSwap 24957 `Low-poly rooms`, Blender 2.7x Cycles, CC-BY. Não copiar 1:1 sem remodelar + creditar (`docs/CONTRATOS.md` §7, `art-source/_REF_INVENTARIO.md`).

## Limitações conhecidas (MVP-1)
- **Só `.glb`, sem `.usdz`:** `art-ios/*.glb` 44/45 (falta `bed_moveis_cadeira.glb`); `.usdz` 0/45 — `catalog.json` aponta para `art-ios/<id>.usdz`, mas nenhum existe. No app, `AssetLoader` cai para caixa teal 0.4m. Conversão oficial é no Mac: `xcrun usdz_converter art-ios/tmp.usdc art-ios/<id>.usdz` (`docs/PIPELINE.md` §3). Sem Mac local, build iOS só via Actions `macos-15`.
- **ID incompleto:** `bed_moveis_cadeira` tem thumb mas está sem `.blend` fonte e sem `.glb` (não é shell — shells BED/KIT/LIV estão completos em `.blend`+`.glb`+`.png`).
- **Thumbs placeholder:** 45/45 existem, mas lote atual é placeholder PIL (fundo `#B08968` + inicial); finais 256px transparentes via `blender -b … --python tools/render_thumb.py` ainda pendentes.
- **Cobertura por quarto:** meta "≥4 opções por categoria/quarto" NÃO atingida em 13/18 combos (ex. quarto-iluminacao 1, quarto-plantas 1, sala-iluminacao 1). Ver matriz em `docs/BUG-BASH.md` BB-12.
- **Não medido:** FPS 60/30, cena <50k tris, monkey 15min, modo avião real, kill-restore em device, CI `ios-build`/`assets-validate` verde remoto (sem `Polyroom.xcodeproj`/xcassets/`Info.plist`; `ALLOW_MISSING=0` hoje dá 45 erros).
- **Requer iOS 17+ portrait;** sem rede por design (qualquer `URLSession` é bug).

## Validações locais (2026-10-05)
- `python3 tools/check_catalog.py` → `itens=45 erros=0` (45 WARNs `.usdz` ausentes, OK até I1).
- `python3 tools/demo_load.py` → `itens=9 erros=0 warns=0`.
- `python3 tools/check_blend.py` (sem Blender) → `encontrados: 44` (full tris/UV pendente — Blender ausente).
