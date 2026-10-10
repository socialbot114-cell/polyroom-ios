# Brief de conteúdo v1.1/v1.2 (p/ S1 modelar)

> 2026-10-10: 2/15 prontos — `piso_tapete_cozinha3` (PISO_TapeteCozinha3,
> 432 tris) e `arte_quadro_cozinha2` (ARTE_QuadroCozinha2, 324 tris), ambos
> com .blend + .glb + thumb + catalog. Lição aprendida: no Blender, ligar
> o nó Color Attribute → Base Color do `Polyroom_PBR`, senão o export glTF
> injeta um `COLOR_0` branco e as cores reais caem em `COLOR_1` (thumb sai
> desbotada). Faltam 13 abaixo.

Matriz room×categoria (2026-10-10, 480 itens): 6 células < 4. Modelar **15
novos** (1 .blend + .glb + thumb cada, mesmos contratos: `Polyroom_PBR`,
vertex color, tris de prop, sem acento) para zerar o déficit:

| # | id sugerido | room | categoria | footprint |
|---|---|---|---|---|
| 1 | `office_porta_canetas_coz` | cozinha | office | S |
| 2 | `office_luminaria_mesa_coz` | cozinha | office | S |
| 3 | `office_quadro_avisos_coz` | cozinha | office | S (wallN) |
| 4 | `office_prateleira_coz` | cozinha | office | S (wallN) |
| 5 | `office_escrivaninha_sala` | sala | office | M |
| 6 | `office_cadeira_escrit_sala` | sala | office | S |
| 7 | `office_luminaria_mesa_sala` | sala | office | S |
| 8 | `office_porta_canetas_sala` | sala | office | S |
| 9 | `mesa_manta_sala` | sala | cama_mesa | S |
| 10 | `mesa_jogo_sala2` | sala | cama_mesa | S |
| 11 | `mesa_toalha_sala2` | sala | cama_mesa | M |
| 12 | `arte_quadro_cozinha2` | cozinha | arte | S (wallN) |
| 13 | `arte_relogio_cozinha2` | cozinha | arte | S (wallN) |
| 14 | `elet_balanca_coz` | cozinha | eletronicos | S |
| 15 | `piso_tapete_cozinha3` | cozinha | piso | M |

Pós-modelagem (S3): entrar em `catalog.json` (+ espelho `Resources/`),
exportar `.glb`, `python3 tools/render_catalog_thumbnails.py --ids …`,
`make_contact_sheet.py --per-category`, gate (`check_catalog` STRICT,
`check_pack`, `check_scale`, `demo_load`).

Wall-mount (S2, app): itens `arte/*` + `parede/*` + quadros/relógios devem
abrir com `mount=wallN, y=1.6` por padrão (`RoomStore.place` já suporta
wallN/wallW; ver `testWallItemGoesToNorthWall`).
