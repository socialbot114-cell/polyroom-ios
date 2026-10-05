# AppIcon 1024 — spec + placeholder

Arquivo: `ios-app/Polyroom/Resources/AppIcon-1024.png` (1024×1024, RGB opaco, placeholder PIL).
Destino final no Xcode: `Assets.xcassets/AppIcon.appiconset/` (gerar no Mac).

## Spec (placeholder cozy, não final)

- Tamanho: 1024×1024 px, RGB sem alfa (App Store recusa transparência).
- Fundo: cozy `#F1E3D3` (241, 227, 211) — mesma base da paleta `docs/CORES-PALETA.md`.
- Cubo isométrico simples, centrado (~440 px de aresta projetada):
  - topo: `#F9F1E6` (claro)
  - esquerda: `#D9A679` (médio quente)
  - direita: `#A9714B` (sombra quente)
  - contorno sutil `#8A5A3B` 4 px
- Letra `P` branca `#FFFFFF`, bold, ~380 px, centrada sobre o cubo.
- Margem segura: nada crítico a < 80 px da borda (evita corte em cantos arredondados iOS).
- Formato: PNG, sem cantos arredondados (iOS aplica máscara).

## Como foi gerado (Linux, reproduzível)

```bash
python3 -c "
from PIL import Image, ImageDraw, ImageFont
# ver script embutido usado no polish: fundo #F1E3D3 + polígonos iso + 'P'
"
# saída: ios-app/Polyroom/Resources/AppIcon-1024.png (1024x1024 RGB)
```

Fonte tentada: `DejaVuSans-Bold` (fallback `load_default` se ausente).
Script desenha 3 losangos (topo/esq/dir) via `ImageDraw.polygon` + texto `P` centralizado com `anchor='mm'`.

## Integração Xcode (no Mac)

1. No Xcode, `Assets.xcassets > AppIcon`: arrastar `AppIcon-1024.png` para slot 1024.
2. Xcode gera 20/29/40/60/76/etc. automaticamente a partir do 1024.
3. `Info.plist` não precisa de `CFBundleIconName` manual (asset catalog resolve).
4. Validar: `Product > Archive > Validate App` checa 1024 sem alfa.

## TODO arte final (v1.1)

- [ ] Substituir `P` por logo Polyroom (quarto iso mini, cama+abajur) mantendo fundo `#F1E3D3`.
- [ ] Exportar via Figma/Sketch em 1024 RGB, depois `sips -g all` para conferir sem alfa.
- [ ] Manter este placeholder até lá — não quebra build (só asset).
