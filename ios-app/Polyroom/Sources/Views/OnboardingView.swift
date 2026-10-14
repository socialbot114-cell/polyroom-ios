import Foundation

#if canImport(SwiftUI)
import SwiftUI

/// Onboarding de 3 cards com persistência em `UserDefaults` (`hasSeenOnboarding`).
///
/// Cards: 1) escolher quarto 2) arrastar e decorar 3) salvar offline.
/// `PolyroomApp` apresenta via `.sheet` quando `!hasSeen()`.
public struct OnboardingView: View {
    public static let seenKey = "hasSeenOnboarding"

    public static func hasSeen() -> Bool {
        UserDefaults.standard.bool(forKey: seenKey)
    }

    public static func markSeen() {
        UserDefaults.standard.set(true, forKey: seenKey)
    }

    public var onDone: () -> Void

    public init(onDone: @escaping () -> Void = {}) {
        self.onDone = onDone
    }

    private let cards: [(emoji: String, titulo: String, texto: String)] = [
        (
            "🏠",
            "Escolha o quarto",
            "Quarto, cozinha ou sala — cada ambiente tem seu espaço e seus itens."
        ),
        (
            "🛋️",
            "Arraste e decore",
            "Coloque móveis do catálogo, mova no grid de 0,25 m, gire 45° e troque a cor da paleta cozy."
        ),
        (
            "💾",
            "Salve offline",
            "Tudo fica no aparelho, sem conta. Coloque móveis (+5 🪙) e tire fotos (+10 🪙) para ganhar cozyCoins!"
        ),
    ]

    public var body: some View {
        VStack(spacing: 16) {
            TabView {
                ForEach(0..<cards.count, id: \.self) { i in
                    VStack(spacing: 12) {
                        Text(cards[i].emoji)
                            .font(.system(size: 64))
                        Text(cards[i].titulo)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        Text(cards[i].texto)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .tag(i)
                }
            }
            .modifier(PageStyleIfAvailable())

            Button {
                Self.markSeen()
                onDone()
            } label: {
                Text("Começar a decorar")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.top, 24)
    }
}

/// `.page` só existe no iOS: no macOS (ex.: `swift test` compilando SwiftUI)
/// mantém o estilo padrão de abas para não quebrar o build.
private struct PageStyleIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.tabViewStyle(.page(indexDisplayMode: .always))
        #else
        content
        #endif
    }
}
#endif
