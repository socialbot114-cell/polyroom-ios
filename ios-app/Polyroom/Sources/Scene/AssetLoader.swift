import Foundation
#if canImport(SceneKit)
import SceneKit
public struct AssetLoader {
    public static func load(catalogId: String) -> SCNNode {
        if let scene = SCNScene(named: catalogId + ".usdz") {
            let n = SCNNode()
            for c in scene.rootNode.childNodes { n.addChildNode(c) }
            return n
        }
        let box = SCNBox(width: 0.4, height: 0.4, length: 0.4, chamferRadius: 0.02)
        print("AssetLoader missing: \(catalogId).usdz")
        #if canImport(UIKit)
        box.firstMaterial?.diffuse.contents = UIColor.systemTeal
        #else
        box.firstMaterial?.diffuse.contents = NSColor.systemTeal
        #endif
        return SCNNode(geometry: box)
    }
}
#else
public struct AssetLoader {
    public static func load(catalogId: String) -> String { "placeholder:\(catalogId)" }
}
#endif
