import Foundation

#if canImport(SwiftUI)
import SwiftUI

/// Bottom-sheet com grid do catálogo por categoria (`Catalog.categories`).
/// Cada célula tem botão "Colocar" -> `store.place(catalogId:)`.
/// (Não substitui `CatalogView` de `PlaceholderViews.swift`.)
public struct CatalogView2: View {
    @ObservedObject public var store: RoomStore
    @State private var categoria: String?

    public init(store: RoomStore) {
        self.store = store
    }

    private var items: [CatalogItem] {
        store.catalog.filter(room: store.currentRoom, categoria: categoria)
    }

    public var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryButton(label: "Todas", value: nil)
                    ForEach(Catalog.categories, id: \.self) { cat in
                        categoryButton(label: cat, value: cat)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)

            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 140), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.nome)
                                .font(.subheadline)
                                .lineLimit(2)
                            Text(item.categoria)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Button("Colocar") {
                                store.place(catalogId: item.id)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    private func categoryButton(label: String, value: String?) -> some View {
        let selected = categoria == value
        return Button(label) { categoria = value }
            .buttonStyle(.bordered)
            .tint(selected ? .accentColor : .secondary)
            .fontWeight(selected ? .semibold : .regular)
    }
}
#endif
