# Conteúdo v1.1 — entrega concluída

> 2026-10-13: **15/15 entregues**, catálogo 495 itens e todas as 45 células
> room×categoria com pelo menos 4 opções. Cada item listado possui .blend,
> .glb, thumbnail e entrada sincronizada nos dois catálogos.
>
> Lição do pipeline: no Blender, ligar
> o nó Color Attribute → Base Color do `Polyroom_PBR`, senão o export glTF
> injeta um `COLOR_0` branco e as cores reais caem em `COLOR_1` (thumb sai
> desbotada.

Os assets seguem `Polyroom_PBR`, vertex colors, orçamentos de tris e IDs ASCII:

| # | id sugerido | room | categoria | footprint |
|---|---|---|---|---|
| 1 | ✅ `office_porta_canetas_coz` | cozinha | office | S |
| 2 | ✅ `office_luminaria_mesa_coz` | cozinha | office | S |
| 3 | ✅ `office_quadro_avisos_coz` | cozinha | office | S (wallN) |
| 4 | ✅ `office_prateleira_coz` | cozinha | office | S (wallN) |
| 5 | ✅ `office_escrivaninha_sala` | sala | office | M |
| 6 | ✅ `office_cadeira_escrit_sala` | sala | office | S |
| 7 | ✅ `office_luminaria_mesa_sala` | sala | office | S |
| 8 | ✅ `office_porta_canetas_sala` | sala | office | S |
| 9 | ✅ `mesa_manta_sala` | sala | cama_mesa | S |
| 10 | ✅ `mesa_jogo_sala2` | sala | cama_mesa | S |
| 11 | ✅ `mesa_toalha_sala2` | sala | cama_mesa | M |
| 12 | ✅ `arte_quadro_cozinha2` | cozinha | arte | S (wallN) |
| 13 | ✅ `arte_relogio_cozinha2` | cozinha | arte | S (wallN) |
| 14 | ✅ `elet_balanca_coz` | cozinha | eletronicos | S |
| 15 | ✅ `piso_tapete_cozinha3` | cozinha | piso | M |

Gate final: `check_catalog` (normal + STRICT), `check_pack`, `check_scale`,
`demo_load`, `check_blend`; previews gerados via `make_contact_sheet.py --per-category`.

Wall-mount (S2, app): itens `arte/*` + `parede/*` + quadros/relógios devem
abrir com `mount=wallN, y=1.6` por padrão (`RoomStore.place` já suporta
wallN/wallW; ver `testWallItemGoesToNorthWall`).
