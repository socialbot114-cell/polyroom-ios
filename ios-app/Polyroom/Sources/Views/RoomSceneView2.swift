import Foundation

// MARK: - Tap-to-select puro (testável no Linux, sem SceneKit/SwiftUI)

/// Resolve o tap em cadeia(s) de nomes de nós (filho -> pai) para o
/// `PlacedItem` correspondente. Os holders de item do `RoomSceneBuilder`
/// têm `name == item.id.uuidString`; nós estáticos ("piso", "parede_norte",
/// "camera_iso", ...) nunca parseiam como UUID conhecido e são ignorados.
/// Retorna `nil` para tap no vazio (chamador deve `store.select(id: nil)`).
public enum RoomSceneTap {
    /// Primeira UUID conhecida na cadeia filho->pai.
    public static func resolve(chain: [String?], known: Set<UUID>) -> UUID? {
        for name in chain {
            guard let name, let id = UUID(uuidString: name), known.contains(id) else { continue }
            return id
        }
        return nil
    }

    /// Primeiro hit (ordem do `hitTest`, mais próximo primeiro) com match.
    public static func resolve(hits: [[String?]], known: Set<UUID>) -> UUID? {
        for chain in hits {
            if let id = resolve(chain: chain, known: known) { return id }
        }
        return nil
    }

    /// Projeta um raio near→far na superfície de arraste da sala.
    /// O plano depende do mount: piso (Y constante), parede norte (Z) ou
    /// parede oeste (X). Retorna coordenadas XZ para `RoomStore.move`.
    public static func worldXZ(
        near: (x: Float, y: Float, z: Float),
        far: (x: Float, y: Float, z: Float),
        mount: String,
        plane: Float
    ) -> (x: Float, z: Float)? {
        let origin: Float
        let direction: Float
        switch mount {
        case "wallN":
            origin = near.z
            direction = far.z - near.z
        case "wallW":
            origin = near.x
            direction = far.x - near.x
        default:
            origin = near.y
            direction = far.y - near.y
        }
        guard abs(direction) > 0.0001 else { return nil }
        let t = (plane - origin) / direction
        guard t >= 0, t <= 1 else { return nil }
        return (near.x + (far.x - near.x) * t,
                near.z + (far.z - near.z) * t)
    }
}

#if canImport(SwiftUI) && canImport(SceneKit)
import SwiftUI
import SceneKit

#if canImport(SceneKit)
// MARK: - Sync incremental (preserva câmera)

/// Sincroniza só os nós de item, sem trocar `scene` (a câmera `camera_iso`
/// e o `pointOfView` manipulado por `allowsCameraControl` ficam intactos).
/// Nós de item = filhos diretos do root com `name` parseável como UUID.
enum RoomSceneSync {
    /// Assinatura dos itens que afetam a cena (posição/rotação/cor/mount/sala).
    /// `selectedId` fica de fora de propósito: só selecionar não recarrega assets.
    static func signature(store: RoomStore) -> String {
        let parts = store.items.map {
            "\($0.id.uuidString)|\($0.catalogId)|\($0.x)|\($0.z)|\($0.y)|\($0.rotationY)|\($0.colorIndex)|\($0.mount)|\($0.room.rawValue)"
        }.sorted().joined(separator: ";")
        return "\(store.currentRoom.rawValue)#\(store.catalog.items.count)#\(parts)"
    }

    /// Transplanta os nós de item de uma cena fresca para `scene`,
    /// removendo obsoletos. Estáticos (piso/paredes/luzes/câmera) intocados.
    static func sync(scene: SCNScene, store: RoomStore) {
        let wanted = Set(store.items.map { $0.id })
        var stale: [SCNNode] = []
        for node in scene.rootNode.childNodes {
            if let n = node.name, let id = UUID(uuidString: n), !wanted.contains(id) {
                stale.append(node)
            }
        }
        for n in stale { n.removeFromParentNode() }
        // Cena fresca só como fonte dos nós de item corretos (geometria +
        // tinta). A cena principal nunca é substituída: câmera preservada.
        let fresh = RoomSceneBuilder.makeScene(store: store)
        for item in store.items {
            let key = item.id.uuidString
            if let existing = scene.rootNode.childNode(withName: key, recursively: false) {
                existing.removeFromParentNode()
            }
            if let freshNode = fresh.rootNode.childNode(withName: key, recursively: false) {
                scene.rootNode.addChildNode(freshNode)
            }
        }
    }

    static func ensure(sceneView: SCNView, store: RoomStore) {
        if sceneView.scene == nil {
            sceneView.scene = RoomSceneBuilder.makeScene(store: store)
        } else {
            sync(scene: sceneView.scene!, store: store)
        }
    }
}
#endif

#if canImport(UIKit)
import UIKit

/// SCNView embrulhada para SwiftUI (iOS). Sync incremental via
/// `RoomSceneSync` a cada `updateUIView` (câmera preservada) + tap-to-select
/// roteando para `RoomStore.select`.
public struct RoomSceneView2: UIViewRepresentable {
    @ObservedObject public var store: RoomStore

    public init(store: RoomStore) {
        self.store = store
    }

    public final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var store: RoomStore?
        var lastSignature: String?
        private var draggedId: UUID?

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? SCNView, let store else { return }
            let point = gesture.location(in: view)
            let hits = view.hitTest(point, options: [:])
            let known = Set(store.items.map { $0.id })
            let chains: [[String?]] = hits.map { hit in
                var chain: [String?] = []
                var node: SCNNode? = hit.node
                var depth = 0
                while let current = node, depth < 6 {
                    chain.append(current.name)
                    node = current.parent
                    depth += 1
                }
                return chain
            }
            // `nil` = tap no vazio -> desseleciona (comportamento documentado).
            store.select(id: RoomSceneTap.resolve(hits: chains, known: known))
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
                  let view = pan.view as? SCNView,
                  let store else { return true }
            let point = pan.location(in: view)
            return itemID(at: point, in: view, store: store) != nil
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? SCNView, let store else { return }
            switch gesture.state {
            case .began:
                let point = gesture.location(in: view)
                guard let id = itemID(at: point, in: view, store: store) else { return }
                draggedId = id
                store.select(id: id)
                view.allowsCameraControl = false
                moveDraggedItem(at: point, in: view, store: store, id: id)
            case .changed:
                guard let id = draggedId else { return }
                moveDraggedItem(at: gesture.location(in: view), in: view, store: store, id: id)
            case .ended, .cancelled, .failed:
                draggedId = nil
                view.allowsCameraControl = true
            default:
                break
            }
        }

        private func itemID(at point: CGPoint, in view: SCNView, store: RoomStore) -> UUID? {
            let hits = view.hitTest(point, options: [:])
            let known = Set(store.items.map { $0.id })
            let chains: [[String?]] = hits.map { hit in
                var chain: [String?] = []
                var node: SCNNode? = hit.node
                var depth = 0
                while let current = node, depth < 6 {
                    chain.append(current.name)
                    node = current.parent
                    depth += 1
                }
                return chain
            }
            return RoomSceneTap.resolve(hits: chains, known: known)
        }

        private func moveDraggedItem(at point: CGPoint, in view: SCNView,
                                     store: RoomStore, id: UUID) {
            guard let item = store.item(id: id) else { return }
            let x = Float(point.x), y = Float(point.y)
            let near = view.unprojectPoint(SCNVector3(x, y, 0))
            let far = view.unprojectPoint(SCNVector3(x, y, 1))
            let plane: Float
            switch item.mount {
            case "wallN": plane = RoomStore.wallZ
            case "wallW": plane = RoomStore.wallX
            default: plane = 0
            }
            guard let position = RoomSceneTap.worldXZ(
                near: (near.x, near.y, near.z),
                far: (far.x, far.y, far.z),
                mount: item.mount,
                plane: plane
            ) else { return }
            store.move(id: id, x: position.x, z: position.z)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = UIColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1)
        view.scene = RoomSceneBuilder.makeScene(store: store)
        context.coordinator.store = store
        context.coordinator.lastSignature = RoomSceneSync.signature(store: store)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        pan.maximumNumberOfTouches = 1
        pan.cancelsTouchesInView = false
        view.addGestureRecognizer(pan)
        return view
    }

    public func updateUIView(_ scnView: SCNView, context: Context) {
        context.coordinator.store = store
        // Só toca a cena se os itens mudaram; seleção sozinha não recarrega.
        let signature = RoomSceneSync.signature(store: store)
        guard context.coordinator.lastSignature != signature || scnView.scene == nil else { return }
        context.coordinator.lastSignature = signature
        RoomSceneSync.ensure(sceneView: scnView, store: store)
    }
}
#elseif canImport(AppKit)
import AppKit

/// SCNView embrulhada para SwiftUI (macOS). Sync incremental via
/// `RoomSceneSync` a cada `updateNSView` (câmera preservada) + click-to-select
/// roteando para `RoomStore.select`.
public struct RoomSceneView2: NSViewRepresentable {
    @ObservedObject public var store: RoomStore

    public init(store: RoomStore) {
        self.store = store
    }

    public final class Coordinator: NSObject {
        weak var store: RoomStore?
        var lastSignature: String?

        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let view = gesture.view as? SCNView, let store else { return }
            let point = gesture.location(in: view)
            let hits = view.hitTest(point, options: [:])
            let known = Set(store.items.map { $0.id })
            let chains: [[String?]] = hits.map { hit in
                var chain: [String?] = []
                var node: SCNNode? = hit.node
                var depth = 0
                while let current = node, depth < 6 {
                    chain.append(current.name)
                    node = current.parent
                    depth += 1
                }
                return chain
            }
            store.select(id: RoomSceneTap.resolve(hits: chains, known: known))
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeNSView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = NSColor(srgbRed: 0.96, green: 0.94, blue: 0.90, alpha: 1)
        view.scene = RoomSceneBuilder.makeScene(store: store)
        context.coordinator.store = store
        context.coordinator.lastSignature = RoomSceneSync.signature(store: store)
        let click = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        view.addGestureRecognizer(click)
        return view
    }

    public func updateNSView(_ scnView: SCNView, context: Context) {
        context.coordinator.store = store
        let signature = RoomSceneSync.signature(store: store)
        guard context.coordinator.lastSignature != signature || scnView.scene == nil else { return }
        context.coordinator.lastSignature = signature
        RoomSceneSync.ensure(sceneView: scnView, store: store)
    }
}
#endif

#elseif canImport(SwiftUI)
import SwiftUI

/// Fallback sem SceneKit (ex.: preview onde SceneKit não linka).
public struct RoomSceneView2: View {
    public var store: RoomStore?

    public init(store: RoomStore? = nil) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.sRGB, red: 0.96, green: 0.94, blue: 0.90, opacity: 1)
            Text("3D indisponível — SceneKit não encontrado")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
#endif
