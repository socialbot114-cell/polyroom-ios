import Foundation

public enum Room: String, Codable, CaseIterable { case quarto, cozinha, sala }
public enum Footprint: String, Codable { case S, M, L }

public struct CatalogItem: Codable, Identifiable {
    public var id: String
    public var nome: String
    public var categoria: String
    public var rooms: [Room]
    public var usdz: String
    public var thumb: String
    public var footprint: Footprint
    public var tintable: Bool
    public var tris: Int?
    public var tags: [String]?
}

public struct CatalogFile: Codable { public var version: Int; public var items: [CatalogItem] }

public struct PlacedItem: Codable, Identifiable {
    public var id: UUID
    public var catalogId: String
    public var room: Room
    public var x: Float; public var z: Float
    public var rotationY: Float
    public var colorIndex: Int
    public init(catalogId: String, room: Room, x: Float = 0, z: Float = 0, rotationY: Float = 0, colorIndex: Int = 0) {
        self.id = UUID(); self.catalogId = catalogId; self.room = room
        self.x = x; self.z = z; self.rotationY = rotationY; self.colorIndex = colorIndex
    }
}

public struct RoomSave: Codable {
    public var version: Int = 1
    public var rooms: [Room: [PlacedItem]] = [.quarto: [], .cozinha: [], .sala: []]
    public var coins: Int = 70
}
