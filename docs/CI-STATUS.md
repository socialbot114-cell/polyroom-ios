# CI-STATUS

> Histórico D1/D3: 45 e depois 480 itens; ver git history.
>
> Estado atual 2026-10-15: 495 catalog items + espelho idêntico; GLB/USDZ/thumbs 495/495; cobertura 45/45 combos com ≥4. Gate local: `check_catalog` e STRICT 495/0, `check_pack` 495/0/0, `demo_load` 9/0, `check_scale` 0 errors (WARNs semânticos documentados), `check_blend` 496/0. CI `ios-build` compila/testa Swift Package (47 testes, inclui import USDZ via SceneKit), gera `.xcodeproj` via XcodeGen e compila o app para iOS Simulator SDK. O runner não oferece serviço/runtime Simulator funcional; teste interativo no simulator/device, Archive e FPS físico seguem pendentes. `assets-validate` e `previews` verdes.

CI remota ativa em repositório público: `socialbot114-cell/polyroom-ios`.
```bash
gh run list --limit 5
gh run watch
```
Workflows esperados: `ios-build`, `assets-validate`, `previews` verdes.
