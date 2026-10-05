import XCTest
@testable import Polyroom
final class CatalogTests: XCTestCase {
    func testDecode() throws {
        let url = URL(fileURLWithPath: "Resources/catalog.json")
        // CI copia catalog.json; teste tolerante à ausência local
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let c = try Catalog.load(from: url)
        XCTAssertGreaterThanOrEqual(c.items.count, 40)
    }
    func testSaveRoundtrip() throws {
        var s = RoomSave()
        s.rooms[.quarto] = [PlacedItem(catalogId: "kit_moveis_cadeira", room: .quarto)]
        let data = try JSONEncoder().encode(s)
        let back = try JSONDecoder().decode(RoomSave.self, from: data)
        XCTAssertEqual(back.rooms[.quarto]?.count, 1)
    }
}
