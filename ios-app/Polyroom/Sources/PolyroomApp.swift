import Foundation

#if canImport(SwiftUI)
import SwiftUI

/// Entry point do app iOS (MVP).
///
/// - Monta `RoomStore` (catálogo do Bundle + save do disco) e `CoinsStore`.
/// - Apresenta `OnboardingView` em `.sheet` na 1ª abertura
///   (`UserDefaults.hasSeenOnboarding`).
///
/// SOBRE `@main` E `swift test`: este arquivo vive no target biblioteca
/// `Polyroom` para o MVP. Se o `@main` ficasse ativo sempre, `swift test`
/// no Mac (onde SwiftUI existe) falharia com entry-point duplicado. Por
/// isso o `@main` só é compilado com a flag `POLYROOM_APP_ENTRY`.
/// No Xcode, ou (A) defina `POLYROOM_APP_ENTRY` em *Active Compilation
/// Conditions* do target app, ou (B) copie este arquivo para um target
/// aplicativo e ative o `@main` manualmente (ver instruções na resposta).
#if POLYROOM_APP_ENTRY
@main
#endif
public struct PolyroomApp: App {
    @StateObject private var store: RoomStore
    @StateObject private var coins: CoinsStore
    @State private var showOnboarding: Bool = !OnboardingView.hasSeen()

    public init() {
        _store = StateObject(wrappedValue: Self.makeStore())
        _coins = StateObject(wrappedValue: CoinsStore())
    }

    public var body: some Scene {
        WindowGroup {
            ContentView(store: store, coins: coins)
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView {
                        showOnboarding = false
                    }
                }
        }
    }

    private static func makeStore() -> RoomStore {
        let s = RoomStore(catalog: loadCatalog())
        s.loadFromDisk()
        return s
    }

    private static func loadCatalog() -> Catalog {
        if let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
           let catalog = try? Catalog.load(from: url)
        {
            return catalog
        }
        return Catalog(items: [])
    }
}
#endif
