import Foundation
#if canImport(SceneKit)
import SceneKit
public struct AssetLoader {
    private static let lock = NSLock()
    private static var templates: [String: SCNNode] = [:]
    private static var missingLogged: Set<String> = []

    public static func load(catalogId: String) -> SCNNode {
        lock.lock()
        defer { lock.unlock() }

        if templates[catalogId] == nil,
           let scene = SCNScene(named: catalogId + ".usdz") {
            let template = SCNNode()
            template.name = "asset_template_\(catalogId)"
            for child in scene.rootNode.childNodes {
                template.addChildNode(child.clone())
            }
            templates[catalogId] = template
        }

        if let template = templates[catalogId] {
            return cloneSubtree(template)
        }
        let box = SCNBox(width: 0.4, height: 0.4, length: 0.4, chamferRadius: 0.02)
        if missingLogged.insert(catalogId).inserted {
            print("AssetLoader missing: \(catalogId).usdz")
        }
        #if canImport(UIKit)
        box.firstMaterial?.diffuse.contents = UIColor.systemTeal
        #else
        box.firstMaterial?.diffuse.contents = NSColor.systemTeal
        #endif
        return SCNNode(geometry: box)
    }

    /// Deep-copies the node hierarchy and its materials. Geometry vertices are
    /// immutable/shared, but materials are per-instance so tinting a duplicate
    /// cannot recolor its source or sibling instances.
    private static func cloneSubtree(_ source: SCNNode) -> SCNNode {
        let copy = SCNNode()
        copy.name = source.name
        copy.transform = source.transform
        copy.pivot = source.pivot
        copy.opacity = source.opacity
        copy.isHidden = source.isHidden
        copy.renderingOrder = source.renderingOrder
        copy.categoryBitMask = source.categoryBitMask

        if let sourceGeometry = source.geometry,
           let geometry = sourceGeometry.copy() as? SCNGeometry {
            geometry.materials = sourceGeometry.materials.map {
                ($0.copy() as? SCNMaterial) ?? $0
            }
            copy.geometry = geometry
        }
        for child in source.childNodes {
            copy.addChildNode(cloneSubtree(child))
        }
        return copy
    }
}
#else
public struct AssetLoader {
    public static func load(catalogId: String) -> String { "placeholder:\(catalogId)" }
}
#endif
