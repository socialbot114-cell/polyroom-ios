# CONTRATOS — trava tudo, ninguém quebra

## 1. Escala e eixos
- `1 Blender unit = 1 metro`, Y-up, Z-forward no export
- Diorama: piso `6x6m`, 2 paredes `h=3m`, espessura `0.2m`, origem no centro do piso
- Aplicar `Ctrl+A > All Transforms` antes de exportar
- Peça pequena: origem na base (pés/chão), não no centro

## 2. Nomes
- `ROOM_Categoria_Nome_vNN`: ex `BED_Moveis_CamaCasals_v01`, `KIT_Aces_Panela_v01`, `LIV_Texteis_TapeteRedondo_v01`
- ROOM: `BED`, `KIT`, `LIV`, `SHARED`
- Categoria: `Moveis`, `Aces`, `Sub`, `Ilum`, `Textil`, `Planta`
- Coleções Blender iguais aos nomes. Sem acento, sem espaço.

## 3. Budget poly/textura
- Quarto shell: <= 15k tris. Quarto montado vazio: <= 50k
- Prop móvel: 1-3k tris. Acessório/sub: 200-1000 tris
- 1 atlas 1024px por quarto (`BED_atlas.png`), props usam vertex color + 1 material `Polyroom_PBR`
- Sem_cycles, sem subdiv, sem boolean não aplicado, UVs sem overlap > 80%

## 4. Export
- Fonte: `art-source/*.blend` (Blender 4.2.1 LTS)
- iOS: `art-ios/<id>.usdz` (Y-up, +Z forward), `thumbnails/<id>.png` 256x256 fundo transparente
- Thumb via: `blender -b file.blend -o thumb_#### -f 1 -- --thumbnail`
- USDZ < 3MB por item, shell < 8MB

## 5. Catalog.json
- Único dono S3. S1/S2 só leem. Schema em `docs/CATALOG-SCHEMA.md`
- `id` = snake_case igual ao usdz sem extensão: `bed_moveis_cama_casal`
- `rooms`: subset de `["quarto","cozinha","sala"]`

## 6. Código iOS
- SwiftUI + SceneKit, iOS 17+, retrato, 60fps, offline-only (sem `URLSession`, sem analytics)
- Pastas: `Models/`, `Views/`, `Scene/`, `Persistence/`, `Resources/catalog.json + *.usdz`
- Save: `Documents/polyroom_save_v1.json` via `SaveManager` Codable. Nunca quebrar compat sem migrar `v1->v2`.

## 7. Não fazer
- Não commitar `.blend1`, `DerivedData/`, `*.xcuserdata`, USDZ >10MB
- Não copiar 1:1 o blend CC-BY sem remodelar + creditar
- Não mexer na pasta do outro sem avisar no TODO-ORQUESTRADOR
