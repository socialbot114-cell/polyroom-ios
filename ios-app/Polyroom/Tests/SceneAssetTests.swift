import XCTest
@testable import Polyroom

#if canImport(SceneKit)
import SceneKit

final class SceneAssetTests: XCTestCase {
    func testRepresentativeUSDZAssetsLoadWithSceneKit() throws {
        // SwiftPM test runs on the macOS host; load a real catalog USDZ by URL
        // so this validates Apple's importer even when no Simulator runtime is installed.
        let testsDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let repoRoot = testsDir
            .deletingLastPathComponent() // Polyroom package
            .deletingLastPathComponent() // ios-app
            .deletingLastPathComponent() // repo
        let ids = [
            "liv_moveis_sofa", "shell_quarto", "office_escrivaninha_sala",
            "arte_relogio_cozinha2", "elet_balanca_coz", "piso_tapete_cozinha3",
        ]
        for id in ids {
            let asset = repoRoot.appendingPathComponent("art-ios/\(id).usdz")
            XCTAssertTrue(FileManager.default.fileExists(atPath: asset.path), asset.path)
            let scene = try SCNScene(url: asset, options: nil)
            var hasGeometry = false
            scene.rootNode.enumerateChildNodes { node, stop in
                if node.geometry != nil {
                    hasGeometry = true
                    stop.pointee = true
                }
            }
            XCTAssertTrue(hasGeometry, "SceneKit deve importar a geometria de \(id)")

            let (minimum, maximum) = scene.rootNode.boundingBox
            let dimensions = [maximum.x - minimum.x, maximum.y - minimum.y, maximum.z - minimum.z]
            XCTAssertTrue(dimensions.contains(where: { $0 > 0.1 }), "USDZ sem dimensão válida: \(id)")
        }
    }
}
#endif
