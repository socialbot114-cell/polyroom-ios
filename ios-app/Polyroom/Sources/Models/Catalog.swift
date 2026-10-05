import Foundation

public struct Catalog {
    public var items: [CatalogItem]
    public static func load(from url: URL) throws -> Catalog {
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder().decode(CatalogFile.self, from: data)
        return Catalog(items: file.items)
    }
    public func filter(room: Room?, categoria: String?) -> [CatalogItem] {
        items.filter { (room == nil || $0.rooms.contains(room!)) && (categoria == nil || $0.categoria == categoria) }
    }
    public static var categories: [String] { ["moveis","acessorios","sub_itens","iluminacao","texteis","plantas"] }
}
