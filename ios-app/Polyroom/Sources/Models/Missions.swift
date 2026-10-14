import Foundation
#if canImport(Combine)
import Combine
#endif

/// 12 missões cozy locais (spec em `docs/MISSOES.md`), sem servidor.
///
/// - Progresso por contagem sobre `RoomSave` + contadores `UserDefaults`
///   (fotos e tintes, que não estão no save).
/// - Recompensa 1x: `claimed` guarda ids já pagos; `evaluate` retorna só as
///   recém-completadas para o chamador creditar via `CoinsStore`.
/// - Lógica pura e testável (`MissionsTests`); sem SceneKit/SwiftUI.
public struct Mission: Identifiable {
    public var id: String // "m01"..."m12"
    public var title: String
    public var reward: Int
    public var goalDescription: String
}

#if canImport(Combine)
public final class MissionStore: ObservableObject {
    @Published public private(set) var claimed: Set<String>
    @Published public private(set) var photosTaken: Int
    @Published public private(set) var tintsDone: Int
#else
public final class MissionStore {
    public private(set) var claimed: Set<String>
    public private(set) var photosTaken: Int
    public private(set) var tintsDone: Int
#endif

    public static let claimedKey = "claimedMissions"
    public static let photosKey = "missionPhotos"
    public static let tintsKey = "missionTints"

    public static let all: [Mission] = [
        Mission(id: "m01", title: "Primeiros passos", reward: 10, goalDescription: "Coloque 3 móveis"),
        Mission(id: "m02", title: "Lar verde", reward: 10, goalDescription: "Coloque 3 plantas"),
        Mission(id: "m03", title: "Clima aconchego", reward: 10, goalDescription: "Coloque 2 iluminação"),
        Mission(id: "m04", title: "Chef", reward: 15, goalDescription: "Cozinha com 5 itens"),
        Mission(id: "m05", title: "Ninho", reward: 15, goalDescription: "Quarto com 5 itens"),
        Mission(id: "m06", title: "Receber bem", reward: 15, goalDescription: "Sala com 6 itens"),
        Mission(id: "m07", title: "Decorador", reward: 15, goalDescription: "3 itens de parede"),
        Mission(id: "m08", title: "Fotógrafo", reward: 20, goalDescription: "Tire 2 fotos"),
        Mission(id: "m09", title: "Colorista", reward: 10, goalDescription: "Tinte 3 itens"),
        Mission(id: "m10", title: "Colecionador", reward: 25, goalDescription: "15 itens num quarto"),
        Mission(id: "m11", title: "Tech", reward: 15, goalDescription: "2 eletrônicos"),
        Mission(id: "m12", title: "Pet friendly", reward: 20, goalDescription: "2 pets + 1 planta"),
    ]

    public init() {
        claimed = Set(UserDefaults.standard.stringArray(forKey: Self.claimedKey) ?? [])
        photosTaken = UserDefaults.standard.integer(forKey: Self.photosKey)
        tintsDone = UserDefaults.standard.integer(forKey: Self.tintsKey)
    }

    /// Registra 1 foto (chamado pelo snapshot). Retorna total.
    @discardableResult
    public func notePhoto() -> Int {
        photosTaken += 1
        UserDefaults.standard.set(photosTaken, forKey: Self.photosKey)
        return photosTaken
    }

    /// Registra 1 tinte (chamado pelo inspector). Retorna total.
    @discardableResult
    public func noteTint() -> Int {
        tintsDone += 1
        UserDefaults.standard.set(tintsDone, forKey: Self.tintsKey)
        return tintsDone
    }

    /// (current, goal) para barra de progresso na UI.
    public func progress(of id: String, in save: RoomSave,
                         categoryOf: (String) -> String?) -> (current: Int, goal: Int) {
        let placed = save.rooms.values.flatMap { $0 }
        func catCount(_ cat: String) -> Int {
            placed.filter { categoryOf($0.catalogId) == cat }.count
        }
        switch id {
        case "m01": return (min(catCount("moveis"), 3), 3)
        case "m02": return (min(catCount("plantas"), 3), 3)
        case "m03": return (min(catCount("iluminacao"), 2), 2)
        case "m04": return (min(save.rooms[.cozinha]?.count ?? 0, 5), 5)
        case "m05": return (min(save.rooms[.quarto]?.count ?? 0, 5), 5)
        case "m06": return (min(save.rooms[.sala]?.count ?? 0, 6), 6)
        case "m07":
            let n = placed.filter { $0.mount.hasPrefix("wall") }.count
            return (min(n, 3), 3)
        case "m08": return (min(photosTaken, 2), 2)
        case "m09": return (min(tintsDone, 3), 3)
        case "m10":
            let n = save.rooms.values.map(\.count).max() ?? 0
            return (min(n, 15), 15)
        case "m11": return (min(catCount("eletronicos"), 2), 2)
        case "m12":
            let pets = catCount("pets"), plants = catCount("plantas")
            // soma simples p/ progresso (completa quando pets>=2 && plantas>=1)
            return (min(pets, 2) + min(plants, 1), 3)
        default: return (0, 1)
        }
    }

    public func isComplete(_ id: String, in save: RoomSave,
                           categoryOf: (String) -> String?) -> Bool {
        if id == "m12" {
            let placed = save.rooms.values.flatMap { $0 }
            let pets = placed.filter { categoryOf($0.catalogId) == "pets" }.count
            let plants = placed.filter { categoryOf($0.catalogId) == "plantas" }.count
            return pets >= 2 && plants >= 1
        }
        let p = progress(of: id, in: save, categoryOf: categoryOf)
        return p.current >= p.goal
    }

    /// Avalia tudo, marca claimed e retorna as recém-completadas (p/ creditar).
    @discardableResult
    public func evaluate(in save: RoomSave,
                         categoryOf: (String) -> String?) -> [Mission] {
        var fresh: [Mission] = []
        for m in Self.all where !claimed.contains(m.id) {
            if isComplete(m.id, in: save, categoryOf: categoryOf) {
                claimed.insert(m.id)
                fresh.append(m)
            }
        }
        if !fresh.isEmpty {
            UserDefaults.standard.set(claimed.sorted(), forKey: Self.claimedKey)
        }
        return fresh
    }

    /// Reseta tudo (testes / onboarding repetido).
    public func reset() {
        claimed = []
        photosTaken = 0
        tintsDone = 0
        UserDefaults.standard.removeObject(forKey: Self.claimedKey)
        UserDefaults.standard.removeObject(forKey: Self.photosKey)
        UserDefaults.standard.removeObject(forKey: Self.tintsKey)
    }
}
