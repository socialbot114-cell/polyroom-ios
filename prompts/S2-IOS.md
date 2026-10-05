# S2 IOS-SWIFT — dono ios-app/

Você é a sessão S2. Trabalha SÓ em `ios-app/`. Leia `catalog.json` mas não edite. Não mexa em `art-source/`.

## D1 (hoje)
1. Leia `docs/CONTRATOS.md`, `docs/GDD.md`, `docs/CATALOG-SCHEMA.md`
2. Se tem Mac+Xcode16: `File > New > Project > iOS App Polyroom`, SwiftUI, bundle `com.polyroom.app`, iOS 17+, portrait. Estrutura:
```
ios-app/Polyroom/{Models/RoomItem.swift,Models/Catalog.swift,Scene/AssetLoader.swift,Scene/RoomScene.swift,Views/RoomSceneView.swift,Views/CatalogView.swift,Views/InspectorView.swift,Persistence/SaveManager.swift,Resources/catalog.json}
```
Se só Linux: crie skeleton SwiftPM + `SaveManager` Codable + `Catalog` decode testável via `swift test` no CI Linux, e deixe `xcodeproj` para o Actions macos criar.
3. Copie `catalog.json` para `Resources/`, crie `SaveManager` com `Documents/polyroom_save_v1.json`, models `PlacedItem(id, uuid, position, rotationY, colorIndex, room)`
4. `RoomSceneView`: SceneKit `SCNView` via `UIViewRepresentable`, grid 6x6, câmera orbit limitada, 3 botões BED/KIT/LIV trocando cor de piso (placeholder até USDZ)
5. `CatalogView`: bottom-sheet lista por categoria com thumb (usa SF Symbol placeholder até thumbs reais)

## D2-D7
- Tap-to-place, drag mover, snap 0.25m, girar 45°, excluir, duplicar
- `AssetLoader.load(id)`: tenta `SCNScene(named: id.usdz)`, fallback cubo colorido se ausente (para CI verde sem assets)
- Snapshot `SCNView.snapshot()` salva PNG local

## Regras
- Offline-only: nenhum `URLSession`. `CODE_SIGNING_ALLOWED=NO` no CI.
- Não quebrar `tools/check_catalog.py`.
