import Foundation

/// Persistência do save (`Documents/polyroom_save_v1.json` via Codable).
///
/// - `load()` nunca crasha: arquivo ausente ou corrompido → retorna `RoomSave()` vazio (fallback anti-crash).
/// - `RoomSave.coins` ≠ `CoinsStore` (`UserDefaults` `cozyCoins`): são economias separadas,
///   não unificar agora (trabalho futuro; ver `CoinsStore.swift`).
/// - Compat: nunca quebrar `v1` sem migrar. `migrate(_:)` é o stub para futura migração `v1 -> v2`.
public struct SaveManager {
    public static var fileName = "polyroom_save_v1.json"
    public static func url() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
    public static func save(_ save: RoomSave) throws {
        let data = try JSONEncoder().encode(save)
        try data.write(to: url(), options: .atomic)
    }
    public static func load() -> RoomSave {
        guard let data = try? Data(contentsOf: url()),
              let s = try? JSONDecoder().decode(RoomSave.self, from: data) else { return RoomSave() }
        return migrate(s)
    }
    /// Stub de migração futura `v1 -> v2`. Hoje só repassa o save (versão 1).
    public static func migrate(_ save: RoomSave) -> RoomSave {
        // TODO futuro: se save.version == 1, converter para schema v2 e bumpar version.
        return save
    }
}
