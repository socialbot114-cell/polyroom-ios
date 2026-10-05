# ios-app — abrir no Mac

Projeto Xcode real será criado no Mac com Xcode 16.2:
`File > New > Project > iOS App`, nome Polyroom, SwiftUI, iOS 17+, portrait, bundle `com.polyroom.app`.

Adicionar arquivos de `Polyroom/Sources/` ao target + `Resources/catalog.json` e `art-ios/*.usdz` em Copy Bundle Resources.

No Linux/CI: `AssetLoader` tem fallback `#else` (sem SceneKit) para validar lógica Codable. Build iOS real roda em `ios-build.yml` (macos-15, `xcodebuild ... iPhone 16`).

Fluxo D2: tap-to-place -> drag mover snap 0.25m -> girar 45° -> SaveManager autosave.
