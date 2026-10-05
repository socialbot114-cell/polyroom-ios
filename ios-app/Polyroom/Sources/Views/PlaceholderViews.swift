import Foundation
#if canImport(SwiftUI)
import SwiftUI
public struct RoomSceneView: View {
    public var room: Room
    public init(room: Room) { self.room = room }
    public var body: some View {
        ZStack {
            Color(.sRGB, red: 0.96, green: 0.94, blue: 0.90, opacity: 1).ignoresSafeArea()
            VStack {
                Text("Polyroom — \(room.rawValue)").font(.headline)
                Text("SceneKit entra aqui no Mac (orbit + snap 0.25m)").font(.caption).foregroundColor(.secondary)
            }
        }
    }
}
public struct CatalogView: View {
    public var items: [CatalogItem]
    public init(items: [CatalogItem]) { self.items = items }
    public var body: some View { List(items) { Text($0.nome) } }
}
public struct InspectorView: View {
    public var body: some View { Text("mover / girar 45° / cor / duplicar / excluir") }
}
#endif
