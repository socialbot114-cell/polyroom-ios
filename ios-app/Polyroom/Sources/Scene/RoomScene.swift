import Foundation

#if canImport(SceneKit)
import SceneKit
#if canImport(UIKit)
import UIKit
/// Tipo de cor da plataforma (iOS).
public typealias RoomPaletteColor = UIColor
#elseif canImport(AppKit)
import AppKit
/// Tipo de cor da plataforma (macOS).
public typealias RoomPaletteColor = NSColor
#endif

/// Monta a `SCNScene` da sala 6x6m a partir do `RoomStore`.
///
/// Conteúdo: piso 6x6 com grid, 2 paredes (norte + oeste),
/// luz directional com sombra + luz ambiente, câmera iso
/// (yaw -30°, pitch 50°) e um nó por `PlacedItem` via
/// `AssetLoader` (posição + rotação Y + cor da paleta).
public final class RoomSceneBuilder {
    private init() {}

    // MARK: - Paleta (docs/CORES-PALETA.md, RGB 0...1)

    /// 6 swatches cozy na ordem do doc: Madeira Clara, Terracota,
    /// Creme Baunilha, Verde Sálvia, Azul Névoa, Grafite Quente.
    public static let paletteHex: [String] = [
        "C9A87A", "D08C60", "F1E3D3", "8FA98F", "A3B8CC", "6C584C",
    ]

    public static let paletteRGB: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [
        (201 / 255, 168 / 255, 122 / 255), // 0 Madeira Clara
        (208 / 255, 140 / 255, 96 / 255),  // 1 Terracota Aconchego
        (241 / 255, 227 / 255, 211 / 255), // 2 Creme Baunilha
        (143 / 255, 169 / 255, 143 / 255), // 3 Verde Sálvia
        (163 / 255, 184 / 255, 204 / 255), // 4 Azul Névoa
        (108 / 255, 88 / 255, 76 / 255),   // 5 Grafite Quente
    ]

    /// Cor da paleta por índice (wrap-around com módulo 6).
    public static func paletteColor(index: Int) -> RoomPaletteColor {
        let c = paletteRGB[abs(index) % paletteRGB.count]
        #if canImport(UIKit)
        return RoomPaletteColor(red: c.r, green: c.g, blue: c.b, alpha: 1)
        #else
        return RoomPaletteColor(srgbRed: c.r, green: c.g, blue: c.b, alpha: 1)
        #endif
    }

    // MARK: - Cena

    /// Cena completa da `store.currentRoom`.
    public static func makeScene(store: RoomStore) -> SCNScene {
        let scene = SCNScene()
        let root = scene.rootNode

        root.addChildNode(makeFloor())
        root.addChildNode(makeGrid())
        for wall in makeWalls() { root.addChildNode(wall) }
        for light in makeLights() { root.addChildNode(light) }

        let camera = makeIsoCamera()
        root.addChildNode(camera)
        // `look(at:)` usa o transform de mundo: chamar após adicionar à cena.
        camera.look(at: SCNVector3Zero)

        scene.background.contents = RoomPaletteColor(
            red: 0.96, green: 0.94, blue: 0.90, alpha: 1
        )

        for item in store.items {
            root.addChildNode(makeItemNode(item, catalog: store.catalog))
        }
        return scene
    }

    // MARK: - Piso / grid / paredes

    private static func makeFloor() -> SCNNode {
        let plane = SCNPlane(width: 6, height: 6)
        plane.firstMaterial?.diffuse.contents = RoomPaletteColor(
            red: 0.93, green: 0.89, blue: 0.83, alpha: 1
        )
        plane.firstMaterial?.isDoubleSided = true
        let node = SCNNode(geometry: plane)
        // SCNPlane é vertical (plano XY): deitar no plano XZ.
        node.eulerAngles.x = -.pi / 2
        node.position = SCNVector3(0, 0, 0)
        node.name = "piso"
        return node
    }

    /// Linhas do grid a cada 1m sobre o piso 6x6 (y = 0.01 anti z-fight).
    private static func makeGrid(step: Float = 1.0, half: Float = 3.0) -> SCNNode {
        var vertices: [SCNVector3] = []
        var i = -half
        while i <= half + 0.001 {
            vertices.append(SCNVector3(i, 0.01, -half))
            vertices.append(SCNVector3(i, 0.01, half))
            vertices.append(SCNVector3(-half, 0.01, i))
            vertices.append(SCNVector3(half, 0.01, i))
            i += step
        }
        let source = SCNGeometrySource(vertices: vertices)
        let indices = (0..<vertices.count).map { Int32($0) }
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        let geo = SCNGeometry(sources: [source], elements: [element])
        geo.firstMaterial?.lightingModel = .constant
        #if canImport(UIKit)
        geo.firstMaterial?.diffuse.contents = UIColor.systemGray3
        #else
        geo.firstMaterial?.diffuse.contents = NSColor.systemGray
        #endif
        let node = SCNNode(geometry: geo)
        node.name = "grid"
        return node
    }

    /// 2 paredes: norte (fundo, z = -3) e oeste (x = -3). Altura 2.6m.
    private static func makeWalls() -> [SCNNode] {
        let color = RoomPaletteColor(red: 0.95, green: 0.92, blue: 0.87, alpha: 1)

        let northGeo = SCNBox(width: 6.2, height: 2.6, length: 0.1, chamferRadius: 0)
        northGeo.firstMaterial?.diffuse.contents = color
        let north = SCNNode(geometry: northGeo)
        north.position = SCNVector3(0, 1.3, -3.05)
        north.name = "parede_norte"

        let westGeo = SCNBox(width: 0.1, height: 2.6, length: 6.2, chamferRadius: 0)
        westGeo.firstMaterial?.diffuse.contents = color
        let west = SCNNode(geometry: westGeo)
        west.position = SCNVector3(-3.05, 1.3, 0)
        west.name = "parede_oeste"

        return [north, west]
    }

    // MARK: - Luzes / câmera

    private static func makeLights() -> [SCNNode] {
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        #if canImport(UIKit)
        sun.light?.color = UIColor(white: 1.0, alpha: 1.0)
        #else
        sun.light?.color = NSColor.white
        #endif
        sun.light?.castsShadow = true
        sun.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
        sun.position = SCNVector3(4, 8, 2)
        sun.name = "sol"
        // Aponta para a origem após entrar na cena (feito pelo chamador? não —
        // `look(at:)` aqui usaria mundo sem pai; então orientamos via ângulos).
        sun.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 6, 0)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        #if canImport(UIKit)
        ambient.light?.color = UIColor(white: 1.0, alpha: 1.0)
        #else
        ambient.light?.color = NSColor.white
        #endif
        ambient.name = "ambiente"

        return [sun, ambient]
    }

    /// Câmera iso: yaw -30° (ao redor de Y), pitch 50° (elevação).
    private static func makeIsoCamera(distance: Float = 11) -> SCNNode {
        let yaw = -30 * Float.pi / 180
        let pitch = 50 * Float.pi / 180
        let node = SCNNode()
        node.camera = SCNCamera()
        node.camera?.fieldOfView = 30
        node.position = SCNVector3(
            distance * cos(pitch) * sin(yaw),
            distance * sin(pitch),
            distance * cos(pitch) * cos(yaw)
        )
        node.name = "camera_iso"
        return node
    }

    // MARK: - Itens

    private static func makeItemNode(_ item: PlacedItem, catalog: Catalog) -> SCNNode {
        let holder = SCNNode()
        holder.position = SCNVector3(item.x, 0, item.z)
        holder.eulerAngles.y = item.rotationY * .pi / 180
        holder.name = item.id.uuidString

        let content = AssetLoader.load(catalogId: item.catalogId)
        // Apoia o modelo no piso (min.y -> 0); se degenerado, mantém 0.
        let (boxMin, boxMax) = content.boundingBox
        if boxMax.y > boxMin.y {
            content.position.y = -boxMin.y
        }
        holder.addChildNode(content)

        // Tinta: só se o item for `tintable` (regra docs/CORES-PALETA.md).
        // Desconhecido no catálogo -> tinta (fallback do AssetLoader é caixa neutra).
        let tintable = catalog.items.first(where: { $0.id == item.catalogId })?.tintable ?? true
        if tintable {
            applyTint(content, index: item.colorIndex)
        }
        return holder
    }

    private static func applyTint(_ node: SCNNode, index: Int) {
        let color = paletteColor(index: index)
        node.enumerateChildNodes { child, _ in
            child.geometry?.materials.forEach { $0.diffuse.contents = color }
        }
        node.geometry?.materials.forEach { $0.diffuse.contents = color }
    }
}
#else
/// Stub sem SceneKit (ex.: Linux `swift build/test`): descreve a cena em texto.
public final class RoomSceneBuilder {
    private init() {}

    public static func makeScene(store: RoomStore) -> String {
        "SceneKit indisponível — \(store.items.count) itens em \(store.currentRoom.rawValue)"
    }
}
#endif
