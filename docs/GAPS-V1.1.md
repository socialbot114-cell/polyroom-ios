# GAPS v1.1 — cobertura, USDZ, xcodeproj

> Estado atual 2026-10-13: **495 itens**, 15 categorias, 495 GLBs + 495 thumbs reais, 0 USDZ (pendência Mac), 0 células de cobertura abaixo de 4. A matriz antiga de 45 e a lista/backlog de 480 itens abaixo são histórico.

Fonte atual: `catalog.json` (495) + `art-ios/*.glb` (495) + `demo_save_v1.json`.
Os trechos de 45/480 itens abaixo são histórico; ver §5b para o estado vigente.

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

## 2. Meta v1.1: 72 itens para >=4/categoria/combo (histórico; concluída)

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

## 3. .usdz 0/495 — pendente Mac

- `art-ios/*.glb`: 495/495 existem.
- `art-ios/*.usdz`: **0/495** (nenhum no repo; `catalog.json` aponta para `art-ios/<id>.usdz`, `tools/check_catalog.py` dá WARN com `ALLOW_MISSING=1`).
- Script pronto: `tools/convert_glb_usdz_mac.sh` (lê ids do `catalog.json`, pula se já existe, `--force` para reconverter).
- Rodar no Mac:
  ```bash
  bash tools/convert_glb_usdz_mac.sh
  python3 tools/check_catalog.py  # WARNs .usdz devem zerar
  ```
- Fallback sem `xcrun`: Reality Converter (arrastar .glb → export .usdz), ver cabeçalho do script + `docs/PIPELINE.md` §3.
- Thumbs: 495/495 renders Blender reais 256×256, documentados em `docs/THUMBNAILS.md`.

## 4. Xcode project e device

- Projeto declarativo: `ios-app/project.yml` (XcodeGen) liga Sources, tests, launch color asset, catalog, sons e thumbs; `Info.plist` configura portrait e permissão de Fotos.
- A CI macOS gera `ios-app/Polyroom.xcodeproj` com XcodeGen, compila o app para iOS Simulator SDK e executa 46 testes SwiftPM. O runner não conecta ao CoreSimulator; teste de runtime fica pendente em Mac com simulator disponível.
- No Mac local: `brew install xcodegen && xcodegen generate --spec ios-app/project.yml --project ios-app` para abrir no Xcode.
- Pendências de release: ícone de produção (PNG atual é placeholder), converter/bundlar 495 USDZ, executar app em simulador/device, Archive Validate e medir FPS em iPhone real.

## 5. Próximos passos Mac

1. Mac/device: converter USDZ e validar escala/carregamento no app.
2. Produzir ícone final, Archive Validate, teste de save/load e FPS em iPhone real.
3. Conteúdo v1.1 concluído; próximas adições entram no escopo v1.2 depois dos gates de device.

## 5b. Cobertura room×categoria atual (15 categorias, 2026-10-13)

Fonte: leitura direta de `catalog.json` (495 itens). Todas as 45 combinações
room×categoria satisfazem a meta de ≥4 itens.

| room | acessorios | arte | cama_mesa | eletrodomesticos | eletronicos | iluminacao | kids | moveis | office | parede | pets | piso | plantas | sub_itens | texteis |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| quarto | 7 | 8 | 6 | 16 | 8 | 22 | 59 | 28 | 17 | 4 | 5 | 4 | 21 | 7 | 5 |
| cozinha | 6 | 4 | 5 | 41 | 4 | 21 | 7 | 20 | 4 | 7 | 4 | 4 | 20 | 7 | 5 |
| sala | 7 | 10 | 4 | 14 | 9 | 26 | 15 | 29 | 4 | 6 | 9 | 5 | 29 | 8 | 6 |

**Déficit: zero células.** O brief `CONTENT-V12.md` foi fechado nos 15 itens
previstos (495 total). Oito combinações estão no mínimo exato de 4: quarto ×
parede/piso; cozinha × arte/eletrônicos/office/piso; sala × cama_mesa/office.

## R2b (thumbs reais) — CONCLUÍDO 2026-10-10; atualizado 2026-10-13
495/495 `thumbnails/<id>.png` 256×256 renderizados da geometria real via
`tools/render_catalog_thumbnails.py` (Blender 4.2.1 headless, EEVEE 64
samples, fundo cozy `#F3EDE4`, 3-point, override por categoria quando a cor
de vértice é plana; detalhe em `docs/THUMBNAILS.md`). Contact-sheet +
15 sheets por categoria regenerados (`previews/`, `thumbs_problema=0`).
Tentativa antiga 14:29 com ortho+sun (thumbs escuras) superada: o pipeline
final usa mundo claro + key/fill/rim + base por categoria (ex. `#C9A87A`-like
p/ moveis) e fundo opaco 256px. O pipeline foi reexecutado para cada item
novo após os batches v1.1; preview geral + 15 sheets gerados de novo.
