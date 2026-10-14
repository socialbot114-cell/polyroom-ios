import XCTest
@testable import Polyroom

// =============================================================================
// CatalogSearchTests — testes puros (sem SwiftUI/SceneKit; rodam no Linux).
//
// O QUE COBREM (task: busca 480 itens + tap + thumbnails):
// - `Catalog.normalized` / `matches` / `filter(room:categoria:query:)`
// - `Catalog.thumbnailCandidates(for:)`
// - `RoomSceneTap.resolve` (mapeamento tap -> UUID, usado pelo Coordinator
//   de `RoomSceneView2` que roteia para `RoomStore.select`)
//
// COMO RODAR NO MAC (Xcode 16.2, iOS 17+) — sem toolchain Swift neste host,
// então a validação aqui foi revisão estática + `python3` no JSON:
/// 1. Lógica pura (Linux ou Mac, sem Xcode):
///      cd ios-app/Polyroom && swift test --filter CatalogSearchTests
/// 2. Suite completa no Mac:
///      cd ios-app/Polyroom && swift test
///    ou no Xcode: open o projeto com os arquivos de `Sources/` no target
///    Polyroom + `Tests/` no target PolyroomTests, Product > Test (Cmd+U).
/// 3. Manual no simulador iPhone 16 (iOS 17+):
///    a) Busca: abrir catálogo, digitar "sofa" (acha "Sofá" se houver
///       acento), "cadeira", parte de id ("geladeira"), tag ("madeira");
///       conferir contador "X de Y" e estado vazio "Nenhum item encontrado"
///       + botão "Limpar busca e filtros". Trocar sala/categoria com busca
///       ativa deve manter ambos os filtros.
///    b) Thumbnails: com `thumbnails/*.png` em Copy Bundle Resources, cada
///       célula mostra a imagem; sem o asset, mostra a inicial (fallback).
///    c) Tap: tocar num móvel colocado seleciona (Inspetor mostra o item);
///       tocar no vazio desseleciona. Conferir que o ID selecionado é o
///       tocado (não o vizinho).
///    d) Câmera: orbitar/zoom, depois Colocar/mover/girar um item — a
///       câmera NÃO deve resetar para a iso inicial.
/// 4. Offline/Codable: sem rede; `demo_save_v1.json` e saves antigos ainda
///    decodam (nenhum campo Codable foi alterado).
// =============================================================================

final class CatalogSearchTests: XCTestCase {

    // MARK: - Massa

    private func item(
        id: String = "kit_moveis_cadeira",
        nome: String = "Cadeira Cozinha",
        categoria: String = "moveis",
        rooms: [Room] = [.quarto, .cozinha, .sala],
        tags: [String]? = ["madeira"]
    ) -> CatalogItem {
        CatalogItem(
            id: id, nome: nome, categoria: categoria, rooms: rooms,
            usdz: "art-ios/\(id).usdz", thumb: "thumbnails/\(id).png",
            footprint: .S, tintable: true, tris: 100, tags: tags
        )
    }

    private func catalog3() -> Catalog {
        Catalog(items: [
            item(id: "bed_moveis_sofa_grande", nome: "Sofá Grande", categoria: "moveis",
                 rooms: [.sala], tags: ["tecido", "conforto"]),
            item(id: "kit_moveis_cadeira", nome: "Cadeira Cozinha", categoria: "moveis",
                 rooms: [.cozinha], tags: ["madeira"]),
            item(id: "arte_quadro_grande", nome: "Quadro Parede", categoria: "arte",
                 rooms: [.sala, .quarto], tags: ["parede"]),
        ])
    }

    // MARK: - normalized

    func testNormalizedStripsAccentsAndCase() {
        XCTAssertEqual(Catalog.normalized("Sofá"), "sofa")
        XCTAssertEqual(Catalog.normalized("ÁRVORE"), "arvore")
        XCTAssertEqual(Catalog.normalized("Cortina"), "cortina")
        XCTAssertEqual(Catalog.normalized("Guarda-roupa"), "guarda-roupa")
    }

    // MARK: - matches por nome/id/tags

    func testMatchesByNomeCaseInsensitive() {
        let i = item(nome: "Cadeira Cozinha")
        XCTAssertTrue(Catalog.matches(i, query: "cadeira"))
        XCTAssertTrue(Catalog.matches(i, query: "CADEIRA"))
        XCTAssertTrue(Catalog.matches(i, query: "cadeira cozinha"))
        XCTAssertFalse(Catalog.matches(i, query: "sofa"))
    }

    func testMatchesAccentInsensitive() {
        let i = item(nome: "Sofá Verde")
        XCTAssertTrue(Catalog.matches(i, query: "sofa"))
        XCTAssertTrue(Catalog.matches(i, query: "SOFÁ"))
        XCTAssertTrue(Catalog.matches(i, query: "sofa verde"))
    }

    func testMatchesByIdSubstring() {
        let i = item(id: "kit_moveis_geladeira", nome: "Geladeira")
        XCTAssertTrue(Catalog.matches(i, query: "geladeira"))
        XCTAssertTrue(Catalog.matches(i, query: "kit_moveis"))
        XCTAssertFalse(Catalog.matches(i, query: "fogao"))
    }

    func testMatchesByTags() {
        let i = item(tags: ["Madeira", "cozy"])
        XCTAssertTrue(Catalog.matches(i, query: "madeira"))
        XCTAssertTrue(Catalog.matches(i, query: "MADEIRA"))
        XCTAssertTrue(Catalog.matches(i, query: "cozy"))
        XCTAssertFalse(Catalog.matches(i, query: "metal"))
    }

    func testMatchesMultiTokenAND() {
        let i = item(id: "bed_moveis_cadeira", nome: "Cadeira Quarto", tags: ["madeira"])
        XCTAssertTrue(Catalog.matches(i, query: "cadeira madeira"))
        XCTAssertFalse(Catalog.matches(i, query: "cadeira metal"))
    }

    func testMatchesNilTagsDoesNotCrash() {
        let i = item(tags: nil)
        XCTAssertTrue(Catalog.matches(i, query: "cadeira"))
        XCTAssertFalse(Catalog.matches(i, query: "madeira"))
    }

    func testEmptyOrBlankQueryMatchesAll() {
        let i = item()
        XCTAssertTrue(Catalog.matches(i, query: ""))
        XCTAssertTrue(Catalog.matches(i, query: "   "))
    }

    // MARK: - filter(room:categoria:query:)

    func testFilterEmptyQueryPreservesOldBehavior() {
        let c = catalog3()
        XCTAssertEqual(c.filter(room: nil, categoria: nil).count, 3)
        XCTAssertEqual(c.filter(room: nil, categoria: nil, query: nil).count, 3)
        XCTAssertEqual(c.filter(room: nil, categoria: nil, query: "").count, 3)
        XCTAssertEqual(c.filter(room: nil, categoria: nil, query: "   ").count, 3)
    }

    func testFilterTwoArgCallSiteStillCompilesAndBehaves() {
        // Chamada antiga de 2 args (CatalogView2 usava; RoomStoreTests usam
        // `filter` indiretamente): deve continuar filtrando só sala/categoria.
        let c = catalog3()
        XCTAssertEqual(c.filter(room: .sala, categoria: nil).count, 2)
        XCTAssertEqual(c.filter(room: .cozinha, categoria: "moveis").count, 1)
    }

    func testFilterQueryAlone() {
        let c = catalog3()
        XCTAssertEqual(c.filter(room: nil, categoria: nil, query: "cadeira").count, 1)
        XCTAssertEqual(c.filter(room: nil, categoria: nil, query: "SOFA").count, 1)
        XCTAssertEqual(c.filter(room: nil, categoria: nil, query: "parede").count, 1)
        XCTAssertEqual(c.filter(room: nil, categoria: nil, query: "xyznada").count, 0)
    }

    func testFilterPreservesRoomAndCategoryWithQuery() {
        let c = catalog3()
        // "moveis" bate em 2 itens, mas só 1 está na sala com categoria arte? -> 0
        XCTAssertEqual(c.filter(room: .sala, categoria: "arte", query: "quadro").count, 1)
        XCTAssertEqual(c.filter(room: .cozinha, categoria: nil, query: "quadro").count, 0)
        XCTAssertEqual(c.filter(room: .sala, categoria: "moveis", query: "sofa").count, 1)
        XCTAssertEqual(c.filter(room: .quarto, categoria: "moveis", query: "sofa").count, 0)
    }

    // MARK: - thumbnails

    func testThumbnailCandidatesContainIdAndBase() {
        let i = item(id: "bed_moveis_cama_casal")
        let cands = Catalog.thumbnailCandidates(for: i)
        XCTAssertTrue(cands.contains("bed_moveis_cama_casal"))
        XCTAssertFalse(cands.isEmpty)
        XCTAssertEqual(cands.count, Set(cands).count, "sem duplicatas")
    }

    func testThumbnailCandidatesWithFolderReferenceVariant() {
        let i = item(id: "abc123")
        let cands = Catalog.thumbnailCandidates(for: i)
        XCTAssertTrue(cands.contains("thumbnails/abc123"),
                      "variante para folder reference no Xcode: \(cands)")
    }

    // MARK: - tap-to-select (RoomSceneTap)

    func testTapResolvesCorrectId() {
        let a = UUID(), b = UUID()
        let known: Set<UUID> = [a, b]
        // Cadeia filho->pai: mesh sem nome, holder com UUID, root.
        XCTAssertEqual(RoomSceneTap.resolve(chain: [nil, a.uuidString, "root"], known: known), a)
        XCTAssertEqual(RoomSceneTap.resolve(chain: [b.uuidString], known: known), b)
    }

    func testTapIgnoresStaticNodesAndUnknownUUIDs() {
        let a = UUID()
        let known: Set<UUID> = [a]
        XCTAssertNil(RoomSceneTap.resolve(chain: ["piso", "camera_iso", nil], known: known))
        XCTAssertNil(RoomSceneTap.resolve(chain: [UUID().uuidString, "root"], known: known))
        XCTAssertNil(RoomSceneTap.resolve(chain: [], known: known))
    }

    func testTapPicksNearestHitFirst() {
        let a = UUID(), b = UUID()
        let known: Set<UUID> = [a, b]
        let hits: [[String?]] = [[b.uuidString, "root"], [a.uuidString, "root"]]
        XCTAssertEqual(RoomSceneTap.resolve(hits: hits, known: known), b)
        XCTAssertNil(RoomSceneTap.resolve(hits: [[nil], ["piso"]], known: known),
                      "tap no vazio -> nil (desseleciona)")
    }

    func testDragProjectionUsesRoomSurfaceForEachMount() {
        let floor = RoomSceneTap.worldXZ(
            near: (x: 0, y: 2, z: 0), far: (x: 2, y: -2, z: 4),
            mount: "floor", plane: 0
        )
        XCTAssertEqual(floor?.x ?? -1, 1, accuracy: 0.001)
        XCTAssertEqual(floor?.z ?? -1, 2, accuracy: 0.001)

        let north = RoomSceneTap.worldXZ(
            near: (x: 0, y: 1, z: 0), far: (x: 2, y: 2, z: -4),
            mount: "wallN", plane: -2
        )
        XCTAssertEqual(north?.x ?? -1, 1, accuracy: 0.001)
        XCTAssertEqual(north?.z ?? -1, -2, accuracy: 0.001)

        let west = RoomSceneTap.worldXZ(
            near: (x: 0, y: 1, z: 0), far: (x: -4, y: 2, z: 2),
            mount: "wallW", plane: -2
        )
        XCTAssertEqual(west?.x ?? -1, -2, accuracy: 0.001)
        XCTAssertEqual(west?.z ?? -1, 1, accuracy: 0.001)

        XCTAssertNil(RoomSceneTap.worldXZ(
            near: (x: 0, y: 1, z: 0), far: (x: 1, y: 1, z: 1),
            mount: "floor", plane: 0
        ))
    }

    // MARK: - Codable/save intacto

    func testCatalogFilterDoesNotAlterSaveCodable() throws {
        var save = RoomSave()
        save.rooms[.sala] = [PlacedItem(catalogId: "kit_moveis_cadeira", room: .sala)]
        let data = try JSONEncoder().encode(save)
        let back = try JSONDecoder().decode(RoomSave.self, from: data)
        XCTAssertEqual(back.rooms[.sala]?.count, 1)
        // Busca não toca no save.
        let c = catalog3()
        XCTAssertEqual(c.filter(room: .sala, categoria: nil, query: "cadeira").count, 0)
        XCTAssertEqual(back.rooms[.sala]?.first?.catalogId, "kit_moveis_cadeira")
    }
}
