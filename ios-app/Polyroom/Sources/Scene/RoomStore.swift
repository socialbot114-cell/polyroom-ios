import Foundation
#if canImport(Combine)
import Combine
#endif

/// Store puro de modelo (sem SceneKit/SwiftUI) para a sala atual.
/// Compila no Linux (swift test) e no Mac (SwiftUI observa via ObservableObject).
#if canImport(Combine)
public final class RoomStore: ObservableObject {
    @Published public var currentRoom: Room
    @Published public var save: RoomSave
    @Published public var selectedId: UUID?
    @Published public var catalog: Catalog
#else
public final class RoomStore {
    public var currentRoom: Room
    public var save: RoomSave
    public var selectedId: UUID?
    public var catalog: Catalog
#endif

    /// Desligue nos testes para não tocar o filesystem.
    public var autosaveEnabled: Bool

    public init(
        currentRoom: Room = .quarto,
        save: RoomSave = RoomSave(),
        selectedId: UUID? = nil,
        catalog: Catalog = Catalog(items: []),
        autosaveEnabled: Bool = true
    ) {
        self.currentRoom = currentRoom
        self.save = save
        self.selectedId = selectedId
        self.catalog = catalog
        self.autosaveEnabled = autosaveEnabled
    }

    // MARK: - Leitura

    /// Itens da sala atual.
    public var items: [PlacedItem] {
        save.rooms[currentRoom] ?? []
    }

    public func items(in room: Room) -> [PlacedItem] {
        save.rooms[room] ?? []
    }

    public func item(id: UUID) -> PlacedItem? {
        for list in save.rooms.values {
            if let found = list.first(where: { $0.id == id }) { return found }
        }
        return nil
    }

    public var selectedItem: PlacedItem? {
        guard let selectedId else { return nil }
        return item(id: selectedId)
    }

    // MARK: - Mutação

    /// Coloca um item do catálogo na sala atual (snap 0.25m + clamp 6x6m). Seleciona o novo item.
    /// Itens de parede (arte/parede/quadro/poster/espelho/relogio/cortina/adesivo/nicho/prateleira/suporte/gancho/chaveiro)
    /// vão para a parede norte (y=1.6) em vez do piso.
    @discardableResult
    public func place(catalogId: String, x: Float = 0, z: Float = 0) -> PlacedItem {
        let wall = Self.isWallItem(catalogId, catalog: catalog)
        let placed = PlacedItem(
            catalogId: catalogId,
            room: currentRoom,
            x: snapClamp(x),
            z: wall ? Self.wallZ : snapClamp(z),
            mount: wall ? "wallN" : "floor",
            y: wall ? Self.wallY : 0
        )
        var list = save.rooms[currentRoom] ?? []
        list.append(placed)
        save.rooms[currentRoom] = list
        selectedId = placed.id
        persist()
        return placed
    }

    /// Move um item (busca em todas as salas; snap + clamp).
    /// Parede norte: move só em x (z travado), parede oeste: só em z.
    public func move(id: UUID, x: Float, z: Float) {
        for (room, list) in save.rooms {
            if let i = list.firstIndex(where: { $0.id == id }) {
                var copy = list
                if copy[i].mount == "wallN" {
                    copy[i].x = snapClamp(x)
                    copy[i].z = Self.wallZ
                } else if copy[i].mount == "wallW" {
                    copy[i].x = Self.wallX
                    copy[i].z = snapClamp(z)
                } else {
                    copy[i].x = snapClamp(x)
                    copy[i].z = snapClamp(z)
                }
                save.rooms[room] = copy
                persist()
                return
            }
        }
    }

    /// Move item de parede entre norte/oeste/piso.
    /// - floor → y = 0 (ignora `y`).
    /// - wallN/wallW → y = clamp(y ?? atual ?? 1.6, 0.6...2.2).
    public func setMount(id: UUID, mount: String, y: Float? = nil) {
        for (room, list) in save.rooms {
            if let i = list.firstIndex(where: { $0.id == id }) {
                var copy = list
                copy[i].mount = mount
                if mount == "wallN" {
                    copy[i].z = Self.wallZ
                    let current = copy[i].y == 0 ? Self.wallY : copy[i].y
                    copy[i].y = min(2.2, max(0.6, y ?? current))
                } else if mount == "wallW" {
                    copy[i].x = Self.wallX
                    let current = copy[i].y == 0 ? Self.wallY : copy[i].y
                    copy[i].y = min(2.2, max(0.6, y ?? current))
                } else {
                    copy[i].y = 0
                }
                save.rooms[room] = copy
                persist()
                return
            }
        }
    }

    public static let wallZ: Float = -2.95
    public static let wallX: Float = -2.95
    public static let wallY: Float = 1.6

    public static func isWallItem(_ catalogId: String, catalog: Catalog) -> Bool {
        let c = catalogId.lowercased()
        if let item = catalog.items.first(where: { $0.id == catalogId }) {
            if item.categoria == "arte" || item.categoria == "parede" { return true }
        }
        for k in ["quadro", "poster", "espelho", "relogio", "cortina", "adesivo", "nicho", "prateleira", "suporte", "gancho", "chaveiro"] {
            if c.contains(k) { return true }
        }
        return false
    }

    /// Gira +step graus (padrão 45°), normalizando para [0, 360).
    public func rotate(id: UUID, step: Float = 45) {
        for (room, list) in save.rooms {
            if let i = list.firstIndex(where: { $0.id == id }) {
                var copy = list
                var r = copy[i].rotationY + step
                r = r.truncatingRemainder(dividingBy: 360)
                if r < 0 { r += 360 }
                // Evita -0.0
                copy[i].rotationY = (r == 0 ? 0 : r)
                save.rooms[room] = copy
                persist()
                return
            }
        }
    }

    /// Remove um item de qualquer sala. Limpa a seleção se era o selecionado.
    public func remove(id: UUID) {
        for (room, list) in save.rooms {
            if list.contains(where: { $0.id == id }) {
                save.rooms[room] = list.filter { $0.id != id }
                if selectedId == id { selectedId = nil }
                persist()
                return
            }
        }
    }

    /// Duplica um item com offset +0.25m em x (com snap+clamp) e novo UUID. Seleciona a cópia.
    /// Preserva mount/y do original (parede continua na parede).
    @discardableResult
    public func duplicate(id: UUID) -> PlacedItem? {
        guard let src = item(id: id) else { return nil }
        let newX: Float
        let newZ: Float
        if src.mount == "wallW" {
            newX = Self.wallX
            newZ = snapClamp(src.z + snapStep)
        } else if src.mount == "wallN" {
            newX = snapClamp(src.x + snapStep)
            newZ = Self.wallZ
        } else {
            newX = snapClamp(src.x + snapStep)
            newZ = snapClamp(src.z)
        }
        let copy = PlacedItem(
            catalogId: src.catalogId,
            room: src.room,
            x: newX,
            z: newZ,
            rotationY: src.rotationY,
            colorIndex: src.colorIndex,
            mount: src.mount,
            y: src.y
        )
        var list = save.rooms[src.room] ?? []
        list.append(copy)
        save.rooms[src.room] = list
        selectedId = copy.id
        persist()
        return copy
    }

    /// Define o índice de cor (tinta). Clampa para 0...5 (6 swatches cozy).
    /// Valores > 5 clampam para 5 (não wrap) para casar com `demo_load.py` (WARN > 5).
    /// Leitura continua compatível com `RoomScene.paletteColor` (wrap via módulo).
    public func setColor(id: UUID, index: Int) {
        let safe = min(5, max(0, index))
        for (room, list) in save.rooms {
            if let i = list.firstIndex(where: { $0.id == id }) {
                var copy = list
                copy[i].colorIndex = safe
                save.rooms[room] = copy
                persist()
                return
            }
        }
    }

    public func select(id: UUID?) {
        selectedId = id
    }

    public func switchRoom(_ room: Room) {
        currentRoom = room
        selectedId = nil
    }

    // MARK: - Persistência

    /// Carrega o save do disco (uso na UI; testes usam init com save explícito).
    public func loadFromDisk() {
        save = SaveManager.load()
        selectedId = nil
    }

    private func persist() {
        guard autosaveEnabled else { return }
        try? SaveManager.save(save)
    }
}
