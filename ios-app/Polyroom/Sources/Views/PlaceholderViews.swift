import Foundation
#if canImport(SwiftUI)
import SwiftUI
public struct RoomSceneView: View {
    public var room: Room
    public var store: RoomStore?
    public init(room: Room, store: RoomStore? = nil) { self.room = room; self.store = store }
    public var body: some View {
        ZStack {
            Color(.sRGB, red: 0.96, green: 0.94, blue: 0.90, opacity: 1).ignoresSafeArea()
            VStack {
                Text("Polyroom — \(room.rawValue)").font(.headline)
                Text("SceneKit entra aqui no Mac (orbit + snap 0.25m)").font(.caption).foregroundColor(.secondary)
                if let store {
                    let count = store.save.rooms[room]?.count ?? 0
                    Text("\(count) itens • snap 0.25m • clamp 6x6m").font(.caption2).foregroundColor(.secondary)
                }
            }
        }
    }
}
public struct CatalogView: View {
    public var items: [CatalogItem]
    public var onPlace: ((String) -> Void)?
    public init(items: [CatalogItem], onPlace: ((String) -> Void)? = nil) { self.items = items; self.onPlace = onPlace }
    public var body: some View {
        List(items) { item in
            HStack {
                Text(item.nome)
                Spacer()
                if onPlace != nil {
                    Button("Colocar") { onPlace?(item.id) }
                        .buttonStyle(.bordered)
                }
            }
        }
    }
}
public struct InspectorView: View {
    public var store: RoomStore?
    public init(store: RoomStore? = nil) { self.store = store }
    public var body: some View {
        if let store, let id = store.selectedId, let item = store.item(id: id) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.catalogId).font(.headline)
                Text(String(format: "x %.2f • z %.2f • %.0f° • cor %d", item.x, item.z, item.rotationY, item.colorIndex))
                    .font(.caption).foregroundColor(.secondary)
                HStack {
                    Button("Girar 45°") { store.rotate(id: id) }
                    Button("Duplicar") { _ = store.duplicate(id: id) }
                    Button("Excluir", role: .destructive) { store.remove(id: id) }
                }.buttonStyle(.bordered)
            }.padding()
        } else {
            Text("mover / girar 45° / cor / duplicar / excluir")
        }
    }
}
#endif
