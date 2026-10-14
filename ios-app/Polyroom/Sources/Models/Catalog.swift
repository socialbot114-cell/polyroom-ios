import Foundation

public struct Catalog {
    public var items: [CatalogItem]
    public init(items: [CatalogItem]) {
        self.items = items
    }
    public static func load(from url: URL) throws -> Catalog {
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder().decode(CatalogFile.self, from: data)
        return Catalog(items: file.items)
    }
    /// Filtro por sala + categoria + busca textual opcional.
    /// `query` combina nome/id/tags, accent-insensitive e case-insensitive
    /// (ver `matches(_:query:)`). `nil`/vazia/branca = sem filtro de texto,
    /// preservando o comportamento antigo de 2 args.
    public func filter(room: Room?, categoria: String?, query: String? = nil) -> [CatalogItem] {
        let q = (query ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return items.filter { item in
            (room.map { item.rooms.contains($0) } ?? true)
                && (categoria.map { item.categoria == $0 } ?? true)
                && (q.isEmpty || Self.matches(item, query: q))
        }
    }

    // MARK: - Busca (pura, testável no Linux)

    /// Normaliza para busca: remove acentos + lowercases (ex.: "Sofá" -> "sofa").
    public static func normalized(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "pt-BR")).lowercased()
    }

    /// `true` se todos os tokens da query aparecem (substring) no
    /// conjunto nome + id + tags normalizados. Query vazia/branca = `true`.
    public static func matches(_ item: CatalogItem, query: String) -> Bool {
        let q = normalized(query).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return true }
        var hay = normalized(item.nome) + " " + normalized(item.id)
        if let tags = item.tags, !tags.isEmpty {
            hay += " " + tags.map { normalized($0) }.joined(separator: " ")
        }
        for token in q.split(separator: " ") {
            if token.isEmpty { continue }
            if !hay.contains(token) { return false }
        }
        return true
    }

    /// Nomes candidatos para `UIImage(named:)`/`NSImage(named:)` a partir de
    /// `item.thumb` ("thumbnails/<id>.png") + `item.id`.
    /// Inclui a variante com prefixo "thumbnails/" para o caso de os PNGs
    /// terem sido adicionados ao Xcode como folder reference. Sem duplicatas.
    public static func thumbnailCandidates(for item: CatalogItem) -> [String] {
        var out: [String] = []
        func push(_ s: String) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty, !out.contains(t) { out.append(t) }
        }
        push(item.id)
        let file = item.thumb.split(separator: "/").last.map(String.init) ?? item.thumb
        let base = file.split(separator: ".").first.map(String.init) ?? file
        push(base)
        if !base.isEmpty { push("thumbnails/" + base) }
        return out
    }
    public static var categories: [String] { ["moveis","acessorios","sub_itens","iluminacao","texteis","plantas","eletronicos","arte","kids","piso","cama_mesa","pets","office","eletrodomesticos","parede"] }
    public static var categoryIcons: [String: String] { ["moveis":"sofa","acessorios":"lamp.table","sub_itens":"gift","iluminacao":"lightbulb","texteis":"refrigerator","plantas":"leaf","eletronicos":"tv","arte":"photo.artframe","kids":"teddybear","piso":"square.grid.3x3","cama_mesa":"bed.double","pets":"pawprint","office":"briefcase","eletrodomesticos":"microwave","parede":"photo.on.rectangle"] }
}
