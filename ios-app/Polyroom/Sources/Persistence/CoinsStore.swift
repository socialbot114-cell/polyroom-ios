import Foundation
#if canImport(Combine)
import Combine
#endif

/// Moedas cozy (`cozyCoins`): economia simples do MVP.
///
/// - Começa com 70.
/// - +5 por móvel novo colocado (`earnPlace()`).
/// - +10 por foto salva (`earnPhoto()`).
/// - Desbloqueio: sala = 20, cozinha = 50 (`unlockCost`).
/// - MVP: `mvpUnlockAll = true` → sala e cozinha já vêm liberadas para teste.
///
/// Persiste em `UserDefaults` (chaves `cozyCoins` / `unlockedRooms`).
/// Não toca em `RoomSave`/`SaveManager` (não quebra persistência existente;
/// unificar `RoomSave.coins` ↔ `CoinsStore` é trabalho futuro).
#if canImport(Combine)
public final class CoinsStore: ObservableObject {
    @Published public private(set) var coins: Int
    @Published public private(set) var unlockedRooms: Set<Room>
#else
public final class CoinsStore {
    public private(set) var coins: Int
    public private(set) var unlockedRooms: Set<Room>
#endif

    public static let coinsKey = "cozyCoins"
    public static let unlockedKey = "unlockedRooms"

    /// Custo de desbloqueio por quarto (quarto é grátis).
    public static let unlockCost: [Room: Int] = [.sala: 20, .cozinha: 50]
    public static let placeReward = 5
    public static let photoReward = 10

    /// MVP: `true` = tudo liberado para teste (padrão).
    public var mvpUnlockAll: Bool

    public init(startingCoins: Int = 70, mvpUnlockAll: Bool = true) {
        self.mvpUnlockAll = mvpUnlockAll
        if let saved = UserDefaults.standard.object(forKey: Self.coinsKey) as? Int {
            self.coins = saved
        } else {
            self.coins = startingCoins
        }
        if let names = UserDefaults.standard.stringArray(forKey: Self.unlockedKey) {
            self.unlockedRooms = Set(names.compactMap(Room.init(rawValue:)))
            self.unlockedRooms.insert(.quarto)
        } else {
            self.unlockedRooms = [.quarto]
        }
        if mvpUnlockAll {
            self.unlockedRooms = Set(Room.allCases)
        }
    }

    // MARK: - Ganhos

    /// +5 por móvel novo colocado.
    public func earnPlace() {
        coins += Self.placeReward
        persist()
    }

    /// +10 por foto salva.
    public func earnPhoto() {
        coins += Self.photoReward
        persist()
    }

    // MARK: - Desbloqueio

    public func cost(for room: Room) -> Int {
        Self.unlockCost[room] ?? 0
    }

    public func isUnlocked(_ room: Room) -> Bool {
        if mvpUnlockAll { return true }
        if room == .quarto { return true }
        return unlockedRooms.contains(room)
    }

    /// Tenta desbloquear `room` descontando o custo. Retorna `true` se
    /// desbloqueado (ou já liberado no MVP). Não desbloqueia sem saldo.
    @discardableResult
    public func unlock(_ room: Room) -> Bool {
        if isUnlocked(room) { return true }
        let price = cost(for: room)
        guard coins >= price else { return false }
        coins -= price
        unlockedRooms.insert(room)
        persist()
        return true
    }

    /// Volta ao estado inicial (útil em testes e no onboarding repetido).
    public func reset(startingCoins: Int = 70) {
        coins = startingCoins
        unlockedRooms = mvpUnlockAll ? Set(Room.allCases) : [.quarto]
        persist()
    }

    // MARK: - Privado

    private func persist() {
        UserDefaults.standard.set(coins, forKey: Self.coinsKey)
        UserDefaults.standard.set(
            unlockedRooms.map(\.rawValue).sorted(),
            forKey: Self.unlockedKey
        )
    }
}
