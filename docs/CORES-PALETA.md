# CORES-PALETA — 6 swatches cozy (para `tintable`)

Uso: só aplicar se `catalog.json → tintable: true` **e** material `Polyroom_PBR`
(ver `docs/CATALOG-SCHEMA.md`). Shells (`shell_*`) são `tintable: false` — não tintear.
Thumbs placeholder do lote D1 usam fundo `#B08968` (categoria `moveis`).

## Paleta

| # | nome | hex | RGB | uso sugerido |
|---|------|-----|-----|--------------|
| 1 | Madeira Clara | `#C9A87A` | 201, 168, 122 | móveis madeira (cama, criado, guarda-roupa, mesa, rack, estante, bancada) |
| 2 | Terracota Aconchego | `#D08C60` | 208, 140, 96 | destaque quente (sofa, cadeira, bancada) |
| 3 | Creme Baunilha | `#F1E3D3` | 241, 227, 211 | base clara / paredes têxteis (sofa, tapetes via tint) |
| 4 | Verde Sálvia | `#8FA98F` | 143, 169, 143 | toque verde dessaturado (cadeira, estante, detalhes) |
| 5 | Azul Névoa | `#A3B8CC` | 163, 184, 204 | contraste frio suave (geladeira, rack, criado) |
| 6 | Grafite Quente | `#6C584C` | 108, 88, 76 | contorno / pés / estrutura escura (mesa, sofa, bancada) |

```text
C9A87A  D08C60  F1E3D3  8FA98F  A3B8CC  6C584C
████████ ████████ ████████ ████████ ████████ ████████
```

## Regras

- `tintable: true` (ex.: `bed_moveis_cama_casal`, `kit_moveis_mesa`, `liv_moveis_sofa`) → pode trocar base color por qualquer swatch acima, mantendo `Polyroom_PBR` vertex color.
- `tintable: false` (ex.: shells, eletros sem PBR) → não tintear; manter cor bakeada.
- Contraste texto-sobre-cor: usar branco `#FFFFFF` sobre 1, 2, 4, 5, 6; usar grafite `#6C584C` sobre 3 (creme).
- Export iOS: bake vertex color antes de `usdz_converter` (ver `docs/PIPELINE.md` §3).

## Exemplo (Blender → vertex color)

1. Selecionar objeto com material `Polyroom_PBR`.
2. `Properties > Material > Base Color` → colar hex da tabela.
3. Se com vertex color: `Viewport Shading > Vertex Paint` → `Paint > Set Vertex Colors` com a cor.
4. Re-export `.glb` / `.usdz`, manter `tris` dentro do budget (`docs/CONTRATOS.md`).

## Cobertura atual

Dos 13 ids com thumb placeholder, 10 são `tintable: true` (todos exceto `shell_quarto`, `shell_cozinha`, `shell_sala`). Paleta pronta para D2 quando os `.blend` reais chegarem.
