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
    /// mount: "floor" | "wallN" | "wallW". y: altura (0 = piso, 1.6 = parede padrão).
    public var mount: String
    public var y: Float
    public init(catalogId: String, room: Room, x: Float = 0, z: Float = 0, rotationY: Float = 0, colorIndex: Int = 0, mount: String = "floor", y: Float = 0) {
        self.id = UUID(); self.catalogId = catalogId; self.room = room
        self.x = x; self.z = z; self.rotationY = rotationY; self.colorIndex = colorIndex
        self.mount = mount; self.y = y
    }
    private enum CodingKeys: String, CodingKey { case id, catalogId, room, x, z, rotationY, colorIndex, mount, y }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        catalogId = try c.decode(String.self, forKey: .catalogId)
        room = try c.decode(Room.self, forKey: .room)
        x = try c.decode(Float.self, forKey: .x)
        z = try c.decode(Float.self, forKey: .z)
        rotationY = try c.decode(Float.self, forKey: .rotationY)
        colorIndex = try c.decode(Int.self, forKey: .colorIndex)
        mount = try c.decodeIfPresent(String.self, forKey: .mount) ?? "floor"
        y = try c.decodeIfPresent(Float.self, forKey: .y) ?? 0
    }
}

public struct RoomSave: Codable {
    public var version: Int = 1
    public var rooms: [Room: [PlacedItem]] = [.quarto: [], .cozinha: [], .sala: []]
    public var coins: Int = 70
}
