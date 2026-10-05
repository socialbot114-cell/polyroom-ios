# CATALOG-SCHEMA

`catalog.json` raiz: `{ "version": 1, "items": [Item] }`

Item:
```json
{
  "id": "bed_moveis_cama_casal",
  "nome": "Cama Casal",
  "categoria": "moveis",
  "rooms": ["quarto"],
  "usdz": "art-ios/bed_moveis_cama_casal.usdz",
  "thumb": "thumbnails/bed_moveis_cama_casal.png",
  "footprint": "M",
  "tintable": true,
  "tris": 2400,
  "tags": ["madeira","cozy"]
}
```
- `categoria`: `moveis|acessorios|sub_itens|iluminacao|texteis|plantas|eletronicos|arte|kids`
- `rooms`: `quarto|cozinha|sala`
- `footprint`: `S|M|L` (S<0.5m, M<1.2m, L>=1.2m)
- Regras: `id` único, arquivos devem existir, `tris` <= budget, `tintable` só se material `Polyroom_PBR`.
