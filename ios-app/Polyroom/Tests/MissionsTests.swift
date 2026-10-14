import XCTest
@testable import Polyroom

/// Testes puros de modelo — sem SceneKit/SwiftUI.
final class MissionsTests: XCTestCase {

    private func makeSave() -> RoomSave { RoomSave() }

    private func cat(_ id: String) -> String? {
        if id.hasPrefix("mov") { return "moveis" }
        if id.hasPrefix("pla") { return "plantas" }
        if id.hasPrefix("ilu") { return "iluminacao" }
        if id.hasPrefix("pet") { return "pets" }
        if id.hasPrefix("eletron") { return "eletronicos" }
        return nil
    }

    private func placed(_ catalogId: String, room: Room = .quarto,
                        mount: String = "floor") -> PlacedItem {
        PlacedItem(catalogId: catalogId, room: room, mount: mount)
    }

    override func setUp() {
        super.setUp()
        MissionStore().reset()
    }

    func testM01ThreeMoveis() {
        let store = MissionStore()
        var save = makeSave()
        save.rooms[.quarto] = [placed("mov_a"), placed("mov_b")]
        XCTAssertFalse(store.isComplete("m01", in: save, categoryOf: cat))
        save.rooms[.quarto]?.append(placed("mov_c"))
        XCTAssertTrue(store.isComplete("m01", in: save, categoryOf: cat))
    }

    func testM04KitchenFive() {
        let store = MissionStore()
        var save = makeSave()
        save.rooms[.cozinha] = (0..<5).map { _ in placed("mov_a", room: .cozinha) }
        XCTAssertTrue(store.isComplete("m04", in: save, categoryOf: cat))
    }

    func testMissionCatalogHasTwelveStableUniqueIDs() {
        XCTAssertEqual(MissionStore.all.count, 12)
        XCTAssertEqual(Set(MissionStore.all.map(\.id)).count, 12)
        XCTAssertEqual(MissionStore.all.first?.id, "m01")
        XCTAssertEqual(MissionStore.all.last?.id, "m12")
    }

    func testCategoryMissionsAndFifteenItemGoal() {
        let store = MissionStore()
        var save = makeSave()
        save.rooms[.quarto] = [
            placed("pla_1"), placed("pla_2"), placed("pla_3"),
            placed("ilu_1"), placed("ilu_2"),
        ]
        XCTAssertTrue(store.isComplete("m02", in: save, categoryOf: cat))
        XCTAssertTrue(store.isComplete("m03", in: save, categoryOf: cat))

        save.rooms[.quarto] = (0..<15).map { index in placed("mov_\(index)") }
        XCTAssertTrue(store.isComplete("m10", in: save, categoryOf: cat))
    }

    func testRoomSpecificGoalsAndElectronics() {
        let store = MissionStore()
        var save = makeSave()
        save.rooms[.quarto] = (0..<5).map { index in placed("mov_\(index)") }
        save.rooms[.sala] = (0..<6).map { index in placed("mov_s\(index)", room: .sala) }
        save.rooms[.cozinha] = [placed("eletron_a", room: .cozinha), placed("eletron_b", room: .cozinha)]
        XCTAssertTrue(store.isComplete("m05", in: save, categoryOf: cat))
        XCTAssertTrue(store.isComplete("m06", in: save, categoryOf: cat))
        XCTAssertTrue(store.isComplete("m11", in: save, categoryOf: cat))
    }

    func testM07WallItems() {
        let store = MissionStore()
        var save = makeSave()
        save.rooms[.sala] = [
            placed("arte_a", room: .sala, mount: "wallN"),
            placed("arte_b", room: .sala, mount: "wallW"),
        ]
        XCTAssertFalse(store.isComplete("m07", in: save, categoryOf: cat))
        save.rooms[.sala]?.append(placed("arte_c", room: .sala, mount: "wallN"))
        XCTAssertTrue(store.isComplete("m07", in: save, categoryOf: cat))
    }

    func testM08PhotosAndM09Tints() {
        let store = MissionStore()
        let save = makeSave()
        XCTAssertFalse(store.isComplete("m08", in: save, categoryOf: cat))
        store.notePhoto(); store.notePhoto()
        XCTAssertTrue(store.isComplete("m08", in: save, categoryOf: cat))
        XCTAssertFalse(store.isComplete("m09", in: save, categoryOf: cat))
        store.noteTint(); store.noteTint(); store.noteTint()
        XCTAssertTrue(store.isComplete("m09", in: save, categoryOf: cat))
    }

    func testM12PetsPlusPlant() {
        let store = MissionStore()
        var save = makeSave()
        save.rooms[.sala] = [
            placed("pet_a", room: .sala),
            placed("pet_b", room: .sala),
        ]
        XCTAssertFalse(store.isComplete("m12", in: save, categoryOf: cat))
        save.rooms[.sala]?.append(placed("pla_a", room: .sala))
        XCTAssertTrue(store.isComplete("m12", in: save, categoryOf: cat))
    }

    func testEvaluateClaimsOnce() {
        let store = MissionStore()
        var save = makeSave()
        save.rooms[.quarto] = [placed("mov_a"), placed("mov_b"), placed("mov_c")]
        let first = store.evaluate(in: save, categoryOf: cat)
        XCTAssertEqual(first.map(\.id), ["m01"])
        XCTAssertEqual(first.map(\.reward), [10])
        let second = store.evaluate(in: save, categoryOf: cat)
        XCTAssertTrue(second.isEmpty) // recompensa 1x
        XCTAssertTrue(MissionStore().claimed.contains("m01"))
    }

    func testProgressValues() {
        let store = MissionStore()
        var save = makeSave()
        save.rooms[.sala] = (0..<4).map { _ in placed("mov_a", room: .sala) }
        let p = store.progress(of: "m06", in: save, categoryOf: cat)
        XCTAssertEqual(p.current, 4)
        XCTAssertEqual(p.goal, 6)
    }
}
