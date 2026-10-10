# Thumbnails do catálogo (renders reais)

As 480 thumbnails em `thumbnails/<id>.png` são renders da **geometria real**
de `art-ios/<id>.glb` (1 PNG 256×256 por id de `catalog.json`). Elas
**substituem os placeholders PIL** anteriores (fundo chapado + letra da
categoria + barras pretas com o id).

## Pipeline determinístico (Blender 4.2 headless)

Script regenerável: `tools/render_catalog_thumbnails.py` (modo duplo —
driver fora do Blender, job de render dentro do Blender).

```bash
# amostra canônica de 5 ids (móvel, planta, parede, luz, eletrônico pequeno)
python3 tools/render_catalog_thumbnails.py --sample

# lote inteiro (480 itens, 2 shards paralelos)
python3 tools/render_catalog_thumbnails.py --all --workers 2 --samples 64

# só verifica os PNGs existentes (tamanho + fundo claro + sem barra preta)
python3 tools/render_catalog_thumbnails.py --verify
```

Pré-requisitos verificados pelo driver **antes de usar**:

- binário Blender 4.2.x em `/tmp/blender-4.2.1-linux-x64/blender`
  (`--blender` ou `$BLENDER_BIN` sobrescrevem; `blender --version` precisa
  conter `Blender 4.2`);
- `catalog.json` íntegro e `art-ios/<id>.glb` presente para cada id.

## Cena padrão por modelo (idêntica para todos — determinística)

1. **Import**: `bpy.ops.import_scene.gltf()` do GLB; falha de um id não
   interrompe os demais (vai para `FAILED_IDS` no log).
2. **Enquadramento automático por bounding box**: bbox mundial de todas as
   malhas, recentralização na origem (só translação — **silhueta
   preservada**, nenhuma escala/deformação), câmera perspectiva 40 mm /
   FOV 40° na direção 3/4 `(1, -1, 0.65)` com fit esférico
   `dist = r·1.12/sin(20°)` e `TRACK_TO` no centro; clip
   `dist/100 … dist·50`.
3. **Fundo cozy claro**: mundo `#F3EDE4` + plano de chão fosco
   (`roughness 0.95`) que recebe sombra e ancora o objeto;
   `film_transparent = False`, PNG 256×256 RGB opaco.
4. **Luz de estúdio suave**: 3 áreas — key `120·s²`, fill `45·s²`,
   rim `60·s²` (energias ∝ raio², lei do inverso do quadrado), sem motion
   blur, EEVEE 64 samples, seed fixa.
5. **Material override por categoria (leitura e contraste)**:
   - primeiro escolhe o atributo de cor de vértice **mais informativo**
     (corrige GLBs cujo atributo ativo é todo branco mas existe outro com
     as cores reais, ex. `parede_quadro_triplo`);
   - modelos com cores próprias informativas são **preservados** (só zera
     `metallic` e impõe `roughness ≥ 0.55` p/ não estourar/escurecer no EEVEE);
   - modelos com cor plana e clara (ex. sofá todo branco) recebem override
     fosco na cor da categoria (`moveis` = madeira quente, `plantas` =
     verde-folha, `iluminacao` = âmbar com emissão 0.35, etc.), com variação
     de tom por parte (`×1.0 / ×0.80 / ×1.14`) para não virar um bloco único.

## Amostra canônica validada visualmente

| id | tipo | resultado |
|---|---|---|
| `liv_moveis_sofa` | móvel | override madeira-clara, silhueta 3/4 legível |
| `liv_planta_grande` | planta | cores originais (vaso + folhas) |
| `parede_quadro_triplo` | item parede | 3 quadros com artes coloridas |
| `bed_ilum_abajur` | luz | cúpula creme + base, brilho âmbar |
| `elet_fone` | eletrônico pequeno | geometria real enquadrada |

## Verificação

- `python3 tools/render_catalog_thumbnails.py --verify` — 480/480 PNG
  256×256, fundo claro (canto > 150), < 0.5% pixels pretos (sem barras).
- `python3 tools/check_catalog.py` e `python3 tools/check_pack.py` passam.
- Regeneração completa leva ~25 min (2 workers EEVEE 64 samples).
