# AppIcon 1024 — Polyroom

Status: arte final atual, gerada por `python3 tools/make_app_icon.py`.

## Arquivos

- `ios-app/Polyroom/Resources/AppIcon-1024.png`: master 1024×1024 RGB opaco.
- `ios-app/Polyroom/Resources/Assets.xcassets/AppIcon.appiconset/`: AppIcon
  universal usado por XcodeGen (`ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`).

## Direção visual

- Mini quarto isométrico em estilo low-poly, remetendo diretamente ao jogo.
- Fundo creme cozy `#F3EDE4`, duas paredes claras e piso madeira suave.
- Cama terracota com travesseiros sálvia, janela azul névoa e criado com planta.
- Contorno castanho quente; sem letras/logotipo tipográfico para leitura em ícone pequeno.
- PNG sem alpha e sem máscara pré-arredondada; iOS aplica o recorte do ícone.

## Regenerar

```bash
python3 tools/make_app_icon.py
```

O script desenha em 4× e reduz com Lanczos para antialiasing. Validação:

```bash
python3 -c "from PIL import Image; im=Image.open('ios-app/Polyroom/Resources/AppIcon-1024.png'); assert im.size==(1024,1024) and im.mode=='RGB'; print(im.size, im.mode)"
```
