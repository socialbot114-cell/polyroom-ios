# CI-STATUS

> Histórico D1/D3: 45 e depois 480 itens; ver git history.
>
> Estado atual 2026-10-14: 495 catalog items + espelho idêntico; thumbs reais 495/495; cobertura 45/45 combos com ≥4. Gate local: `check_catalog` e STRICT 495/0, `check_pack` 495/0/0, `demo_load` 9/0, `check_scale` 0 errors (WARNs semânticos documentados), `check_blend` 496/0. CI `ios-build` compila o Swift Package (46 testes, 0 falhas) e gera `.xcodeproj` via XcodeGen para build + XCTest no iPhone 16 Simulator. `assets-validate` e `previews` verdes. Mac/device ainda necessários para USDZ do bundle, Archive real e FPS físico.

CI remota ativa em repositório público: `socialbot114-cell/polyroom-ios`.
```bash
gh run list --limit 5
gh run watch
```
Workflows esperados: `ios-build`, `assets-validate`, `previews` verdes.
