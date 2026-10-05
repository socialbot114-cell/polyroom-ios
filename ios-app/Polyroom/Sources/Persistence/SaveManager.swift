import Foundation

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
        return s
    }
}
