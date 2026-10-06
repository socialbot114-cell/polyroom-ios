# GAPS v1.1 — cobertura, USDZ, xcodeproj

> Estado 2026-10-06: 480 itens — matriz 45 abaixo está OBSOLETA (mantida só p/ histórico). Recount completo delegado ao agente catalog (não feito aqui).
> Contagens novas via leitura `catalog.json` (2026-10-06): total 480; por categoria: `moveis` 70, `kids` 69, `plantas` 66, `eletrodomesticos` 64, `iluminacao` 63, `sub_itens` 18, `acessorios` 17, `pets` 17, `office` 17, `parede` 16, `texteis` 15, `arte` 12, `eletronicos` 12, `piso` 12, `cama_mesa` 12. Slots por room (com overlap): quarto 217, sala 174, cozinha 151. Assets: `.glb` 480/480, `.usdz` 0/480, `.blend` 481.
> Meta "≥4/categoria/combo" precisa ser recalculada p/ 15 categorias atuais (agente catalog).

Fonte verdade: `catalog.json` v1 (45 únicos) + `art-ios/*.glb` (45) + `demo_save_v1.json`.
Data: 2026-10-05. Polish final — não quebra nada existente (sem editar blends nem `Sources/*.swift`).

## 1. Cobertura atual por categoria/combo

Ordem tabelas: `moveis / acessorios / sub_itens / iluminacao / texteis / plantas`.

| room | total slots | moveis | acessorios | sub_itens | iluminacao | texteis | plantas |
|------|-------------|--------|------------|-----------|------------|---------|---------|
| quarto | 17 | 8 | 3 | 2 | 1 | 2 | 1 |
| cozinha | 18 | 7 | 4 | 2 | 1 | 2 | 2 |
| sala | 20 | 8 | 5 | 2 | 1 | 2 | 2 |
| **únicos (45)** | 45 | **20** | **9** | **5** | **3** | **5** | **3** |

Slots = soma com compartilhados (17+18+20=55). Únicos = 45.

Detalhe quarto (17): `bed_moveis_*` 6 (cama_casal, criado, guarda_roupa, escrivaninha, cadeira, luminaria_pe) + `liv_moveis_estante` + `shell_quarto` = 8 moveis; acessorios 3 (livros, quadro, relogio); sub 2 (almofada, caixa); ilum 1 (abajur); texteis 2 (tapete, cortina); plantas 1 (vaso).

Detalhe cozinha (18): moveis 7 (bancada, armario, geladeira, fogao, mesa, cadeira + shell_cozinha); acessorios 4 (panela, pratos, torneira + relogio compartilhado); sub 2 (frutas, tabuinha); ilum 1 (pendente); texteis 2 (pano, tapete); plantas 2 (temperos + vaso compartilhado).

Detalhe sala (20): moveis 8 (sofa, rack, tv, estante, mesa_centro + cadeira/luminaria_pe compartilhados + shell_sala); acessorios 5 (quadro, livros, vaso_decor + livros/quadro_bed compartilhados); sub 2 (almofada_liv + almofada_bed); ilum 1 (chao); texteis 2 (tapete_redondo + cortina_bed); plantas 2 (grande + vaso_bed).

Compartilhados (9, economizam modelagem mas mascaram gap): `bed_moveis_cadeira`, `bed_aces_livros`, `bed_aces_quadro`, `bed_sub_almofada`, `bed_moveis_luminaria_pe`, `bed_textil_cortina`, `liv_moveis_estante` (quarto↔sala), `bed_aces_relogio` (quarto↔cozinha), `bed_planta_vaso` (3 rooms).

## 2. Meta v1.1: 72 itens para >=4/categoria/combo

Regra: cada combo room×categoria precisa de >=4 opções para filtro/catálogo não parecer vazio e combos decor funcionarem.
72 = 3 rooms × 6 categorias × 4.

Déficit bruto por combo (para chegar a 4):

| room | moveis | acess | sub | ilum | text | plantas | subtotal bruto |
|------|--------|-------|-----|------|------|---------|----------------|
| quarto | 0 (+4 surplus) | +1 | +2 | +3 | +2 | +3 | 11 |
| cozinha | 0 (+3) | 0 | +2 | +3 | +2 | +2 | 9 |
| sala | 0 (+4) | 0 (+1) | +2 | +3 | +2 | +2 | 9 |

- Bruto: 29 slots faltantes se ignorar surplus.
- Líquido: 72 − 55 slots atuais = **17 slots**.
- Em únicos: 72 − 45 = **27 novos .blend/.glb** se todos single-room (caminho recomendado: garante >=4 exclusivos por combo; compartilhados reduzem o número mas não resolvem variedade por categoria).

Backlog sugerido (27 únicos, prioridade onde gap é 3):
- iluminacao +9 (3 por room: pendente/quarto ×2, fita LED, luminária mesa cozinha/sala ×2, arandela, abajur variants)
- plantas +7 (quarto +3: suculenta, jiboia pendente, vaso médio; cozinha +2, sala +2)
- sub_itens +6 (2 por room: livros/caixas/vasos pequenos variants)
- texteis +4 (quarto +2: almofada/lençol set; cozinha +1, sala +1)
- acessorios +1 (quarto: espelho parete — tira quarto de 3→4)
- moveis 0 (já >=4 em todos; só v1.2: beliche, ilha cozinha, poltrona sala)

## 3. .usdz 0/45 — pendente Mac

- `art-ios/*.glb`: 45/45 existem (fallback Linux OK).
- `art-ios/*.usdz`: **0/45** (nenhum no repo; `catalog.json` aponta para `art-ios/<id>.usdz`, `tools/check_catalog.py` dá WARN com `ALLOW_MISSING=1`).
- Script pronto: `tools/convert_glb_usdz_mac.sh` (loop 45 ids do `catalog.json`, pula se já existe, loga `du -h`, `--force` para reconverter).
- Rodar no Mac:
  ```bash
  bash tools/convert_glb_usdz_mac.sh
  python3 tools/check_catalog.py  # WARNs .usdz devem zerar
  ```
- Fallback sem `xcrun`: Reality Converter (arrastar .glb → export .usdz), ver cabeçalho do script + `docs/PIPELINE.md` §3.
- Thumbs: 45/45 placeholders PIL 256px existem; trocar por render Blender 256px transparente na v1.1 (não bloqueia).

## 4. xcodeproj — pendente Mac

- Existe: `ios-app/Polyroom/Package.swift` (iOS 17), `Sources/` (Models/Persistence/Scene/Views), `Tests/`, `Resources/catalog.json`, `README-ASSETS.md`.
- Criados neste polish: `ios-app/Polyroom/Info.plist` (mínimo iOS17 portrait: `CFBundleName` Polyroom, `UILaunchStoryboardName`, `UISupportedInterfaceOrientations` portrait, `NSPhotoLibraryAddUsageDescription` "Salvar fotos do seu quarto"), `ios-app/AppIcon-1024-spec.md` + `ios-app/Polyroom/Resources/AppIcon-1024.png` (1024 RGB placeholder `#F1E3D3` + cubo + "P").
- Falta (só no Mac, Xcode 16.2): `ios-app/Polyroom.xcodeproj` / `.xcworkspace`:
  1. `File > New > Project > iOS App`, nome Polyroom, SwiftUI, iOS 17+, portrait, bundle `com.polyroom.app`.
  2. Adicionar `Sources/` ao target + `Resources/catalog.json` e `art-ios/*.usdz` em `Copy Bundle Resources`.
  3. Arrastar `AppIcon-1024.png` para `Assets.xcassets/AppIcon` (slot 1024).
  4. CI `ios-build.yml` (macos-15, `xcodebuild ... iPhone 16`) valida lá.
- Não gerar xcodeproj no Linux (formato Xcode-only, quebraria diff).

## 5. Próximos passos (ordem)

1. Mac: `bash tools/convert_glb_usdz_mac.sh` → commit 45 `.usdz` → `ALLOW_MISSING=0 python3 tools/check_catalog.py` verde.
2. Mac: criar xcodeproj + Archive Validate (checa Info.plist + AppIcon 1024 sem alfa).
3. Modelar backlog §2 (ilum/plantas/sub primeiro), export `.glb`, thumb Blender, atualizar `catalog.json` (manter espelho em `Resources/catalog.json`).
4. Recalcular este doc: meta é zerar tabela de déficit (todas as 18 células >=4).

## R2b (thumbs reais)
Tentativa 14:29 com ortho+sun gerou thumbs escuras (materiais cinza, falta 3-point + HDRI) — revertido para placeholders PIL. Refazer com: world HDRI cozy, key/fill/rim, material base #C9A87A e fundo #F1E3D3 opaco 256px.
