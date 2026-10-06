import XCTest
@testable import Polyroom

/// Testes puros de modelo — sem SceneKit/SwiftUI.
final class RoomStoreTests: XCTestCase {

    private func makeStore() -> RoomStore {
        RoomStore(currentRoom: .quarto, save: RoomSave(), autosaveEnabled: false)
    }

    func testSnap() {
        XCTAssertEqual(snap(0.12), 0.0, accuracy: 0.001)
        XCTAssertEqual(snap(0.13), 0.25, accuracy: 0.001)
        XCTAssertEqual(snap(1.0), 1.0, accuracy: 0.001)
        XCTAssertEqual(snap(-0.13), -0.25, accuracy: 0.001)
    }

    func testPlaceSnapsAndSelects() {
        let store = makeStore()
        let item = store.place(catalogId: "kit_moveis_cadeira", x: 0.13, z: 0.12)
        XCTAssertEqual(item.x, 0.25, accuracy: 0.001)
        XCTAssertEqual(item.z, 0.0, accuracy: 0.001)
        XCTAssertEqual(item.room, .quarto)
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.selectedId, item.id)
    }

    func testPlaceClampsTo6x6() {
        let store = makeStore()
        let item = store.place(catalogId: "kit_moveis_cadeira", x: 10, z: -10)
        XCTAssertEqual(item.x, 3.0, accuracy: 0.001)
        XCTAssertEqual(item.z, -3.0, accuracy: 0.001)
    }

    func testMoveSnapsAndClamps() {
        let store = makeStore()
        let item = store.place(catalogId: "kit_moveis_cadeira")
        store.move(id: item.id, x: 1.13, z: 99)
        let moved = store.item(id: item.id)!
        XCTAssertEqual(moved.x, 1.25, accuracy: 0.001)
        XCTAssertEqual(moved.z, 3.0, accuracy: 0.001)
    }

    func testRotateWrapsAt360() {
        let store = makeStore()
        let item = store.place(catalogId: "kit_moveis_cadeira")
        for _ in 0..<8 { store.rotate(id: item.id) } // 8x45 = 360
        XCTAssertEqual(store.item(id: item.id)!.rotationY, 0, accuracy: 0.001)
        store.rotate(id: item.id)
        XCTAssertEqual(store.item(id: item.id)!.rotationY, 45, accuracy: 0.001)
    }

    func testRemoveClearsSelection() {
        let store = makeStore()
        let item = store.place(catalogId: "kit_moveis_cadeira")
        XCTAssertEqual(store.selectedId, item.id)
        store.remove(id: item.id)
        XCTAssertTrue(store.items.isEmpty)
        XCTAssertNil(store.selectedId)
    }

    func testDuplicateAndSetColor() {
        let store = makeStore()
        let item = store.place(catalogId: "kit_moveis_cadeira", x: 0, z: 0)
        store.setColor(id: item.id, index: 2)
        XCTAssertEqual(store.item(id: item.id)!.colorIndex, 2)
        let copy = store.duplicate(id: item.id)!
        XCTAssertNotEqual(copy.id, item.id)
        XCTAssertEqual(copy.catalogId, item.catalogId)
        XCTAssertEqual(copy.colorIndex, 2)
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.selectedId, copy.id)
    }

    func testWallItemGoesToNorthWall() {
        var catalog = Catalog(items: [])
        let store = RoomStore(currentRoom: .sala, save: RoomSave(), catalog: catalog, autosaveEnabled: false)
        // sem catálogo, detecção por nome ainda vale para quadro
        let item = store.place(catalogId: "arte_quadro_grande", x: 1.0, z: 1.0)
        XCTAssertEqual(item.mount, "wallN")
        XCTAssertEqual(item.z, RoomStore.wallZ, accuracy: 0.001)
        XCTAssertEqual(item.y, RoomStore.wallY, accuracy: 0.001)
        store.move(id: item.id, x: 2.0, z: 2.0)
        let moved = store.item(id: item.id)!
        XCTAssertEqual(moved.x, 2.0, accuracy: 0.001)
        XCTAssertEqual(moved.z, RoomStore.wallZ, accuracy: 0.001)
        _ = catalog
    }

    func testFloorItemStaysOnFloor() {
        let store = makeStore()
        let item = store.place(catalogId: "kit_moveis_cadeira", x: 0.5, z: 0.5)
        XCTAssertEqual(item.mount, "floor")
        XCTAssertEqual(item.y, 0, accuracy: 0.001)
    }

    func testSaveRoundtrip() throws {
        let store = makeStore()
        let item = store.place(catalogId: "kit_moveis_cadeira", x: 0.5, z: -0.5)
        store.rotate(id: item.id)
        let data = try JSONEncoder().encode(store.save)
        let back = try JSONDecoder().decode(RoomSave.self, from: data)
        XCTAssertEqual(back.rooms[.quarto]?.count, 1)
        XCTAssertEqual(back.rooms[.quarto]?.first?.rotationY ?? -1, 45, accuracy: 0.001)
        // Roundtrip de volta ao store
        let store2 = RoomStore(currentRoom: .quarto, save: back, autosaveEnabled: false)
        XCTAssertEqual(store2.items.count, 1)
    }

    func testSetColorClampsTo0To5() {
        let store = makeStore()
        let item = store.place(catalogId: "kit_moveis_cadeira")
        store.setColor(id: item.id, index: -1)
        XCTAssertEqual(store.item(id: item.id)!.colorIndex, 0)
        store.setColor(id: item.id, index: 99)
        XCTAssertEqual(store.item(id: item.id)!.colorIndex, 5)
        store.setColor(id: item.id, index: 5)
        XCTAssertEqual(store.item(id: item.id)!.colorIndex, 5)
    }

    func testRotateNegativeGoesTo315() {
        let store = makeStore()
        let item = store.place(catalogId: "kit_moveis_cadeira")
        store.rotate(id: item.id, step: -45)
        XCTAssertEqual(store.item(id: item.id)!.rotationY, 315, accuracy: 0.001)
    }

    func testRotateFullCircleHasNoMinusZero() {
        let store = makeStore()
        let item = store.place(catalogId: "kit_moveis_cadeira")
        for _ in 0..<8 { store.rotate(id: item.id) }
        let r = store.item(id: item.id)!.rotationY
        XCTAssertEqual(r, 0, accuracy: 0.001)
        XCTAssertEqual(r.sign, .plus)
    }

    func testDuplicatePreservesWallMountAndY() {
        let store = makeStore()
        let item = store.place(catalogId: "arte_quadro_grande", x: 1.0, z: 1.0)
        XCTAssertEqual(item.mount, "wallN")
        XCTAssertEqual(item.y, RoomStore.wallY, accuracy: 0.001)
        let copy = store.duplicate(id: item.id)!
        XCTAssertEqual(copy.mount, "wallN")
        XCTAssertEqual(copy.y, item.y, accuracy: 0.001)
        XCTAssertEqual(copy.z, RoomStore.wallZ, accuracy: 0.001)
        XCTAssertEqual(copy.x, snapClamp(item.x + snapStep), accuracy: 0.001)
    }

    func testDuplicateClampsAtBorder() {
        let store = makeStore()
        let item = store.place(catalogId: "kit_moveis_cadeira", x: 2.9, z: 0)
        XCTAssertEqual(item.x, 3.0, accuracy: 0.001)
        let copy = store.duplicate(id: item.id)!
        XCTAssertEqual(copy.x, 3.0, accuracy: 0.001)
    }
}
