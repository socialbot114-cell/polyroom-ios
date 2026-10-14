import Foundation

#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Bottom-sheet com grid do catálogo por categoria (`Catalog.categories`).
/// Cada célula tem botão "Colocar" -> `store.place(catalogId:)`.
///
/// Busca (480 itens): filtra por nome/id/tags, accent-insensitive e
/// case-insensitive via `Catalog.filter(room:categoria:query:)`. Mostra
/// contador "X de Y" e estado vazio com ação de limpar.
/// Thumbnails: tenta `UIImage`/`NSImage(named:)` com
/// `Catalog.thumbnailCandidates(for:)` (bundle do app quando os
/// `thumbnails/*.png` forem adicionados em Copy Bundle Resources);
/// fallback = bloco atual (inicial do nome).
/// (Não substitui `CatalogView` de `PlaceholderViews.swift`.)
public struct CatalogView2: View {
    @ObservedObject public var store: RoomStore
    @State private var categoria: String?
    @State private var busca: String = ""

    public init(store: RoomStore) {
        self.store = store
    }

    /// Itens após filtro de sala/categoria, sem texto (denominador do contador).
    private var baseItems: [CatalogItem] {
        store.catalog.filter(room: store.currentRoom, categoria: categoria)
    }

    /// Itens após sala/categoria + busca.
    private var items: [CatalogItem] {
        store.catalog.filter(room: store.currentRoom, categoria: categoria, query: busca)
    }

    public var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 8)

            // Busca textual.
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Buscar por nome, id ou tag", text: $busca)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    #if canImport(UIKit)
                    .textInputAutocapitalization(.never)
                    #endif
                    .accessibilityLabel("Buscar no catálogo")
                if !busca.isEmpty {
                    Button {
                        busca = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Limpar busca")
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 4)

            // Contador: filtrados (com busca) de base (sala/categoria).
            Text("\(items.count) de \(baseItems.count) itens")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 4)
                .accessibilityLabel("contador: \(items.count) de \(baseItems.count)")

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

            if items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Nenhum item encontrado")
                        .font(.headline)
                    Text("Tente outro nome, id ou tag — ou limpe a busca e os filtros de sala/categoria.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    if !busca.isEmpty || categoria != nil {
                        Button("Limpar busca e filtros") {
                            busca = ""
                            categoria = nil
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 140), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(items) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                CatalogThumbView(item: item)
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
                                .accessibilityLabel("Colocar \(item.nome)")
                                .accessibilityHint("Adiciona este item à sala atual")
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
    }

    private func categoryButton(label: String, value: String?) -> some View {
        let selected = categoria == value
        return Button(label) { categoria = value }
        .buttonStyle(.bordered)
        .tint(selected ? .accentColor : .secondary)
        .fontWeight(selected ? .semibold : .regular)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Thumbnail do bundle quando existir; fallback = inicial do nome.
///
/// Procura `Catalog.thumbnailCandidates(for:)` via `UIImage(named:)` (iOS)
/// ou `NSImage(named:)` (macOS). No Xcode, arrastar `thumbnails/*.png`
/// para Copy Bundle Resources (ver `Resources/README-ASSETS.md`).
private struct CatalogThumbView: View {
    let item: CatalogItem

    var body: some View {
        Group {
            #if canImport(UIKit)
            if let ui = Self.loadUIImage(for: item) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
            } else {
                fallback
            }
            #elseif canImport(AppKit)
            if let ns = Self.loadNSImage(for: item) {
                Image(nsImage: ns)
                    .resizable()
                    .scaledToFit()
            } else {
                fallback
            }
            #else
            fallback
            #endif
        }
        .frame(height: 64)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.12))
        .cornerRadius(8)
        .accessibilityHidden(true)
    }

    private var fallback: some View {
        Text(String(item.nome.prefix(1)).uppercased())
            .font(.largeTitle)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    #if canImport(UIKit)
    private static func loadUIImage(for item: CatalogItem) -> UIImage? {
        for name in Catalog.thumbnailCandidates(for: item) {
            if let img = UIImage(named: name) { return img }
        }
        return nil
    }
    #elseif canImport(AppKit)
    private static func loadNSImage(for item: CatalogItem) -> NSImage? {
        for name in Catalog.thumbnailCandidates(for: item) {
            if let img = NSImage(named: name) { return img }
        }
        return nil
    }
    #endif
}
#endif
