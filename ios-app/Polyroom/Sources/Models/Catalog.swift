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
    public static var categories: [String] { ["moveis","acessorios","sub_itens","iluminacao","texteis","plantas","eletronicos","arte","kids","piso","cama_mesa","pets","office","eletrodomesticos","parede"] }
    public static var categoryIcons: [String: String] { ["moveis":"sofa","acessorios":"lamp.table","sub_itens":"gift","iluminacao":"lightbulb","texteis":"refrigerator","plantas":"leaf","eletronicos":"tv","arte":"photo.artframe","kids":"teddybear","piso":"square.grid.3x3","cama_mesa":"bed.double","pets":"pawprint","office":"briefcase","eletrodomesticos":"microwave","parede":"photo.on.rectangle"] }
}
