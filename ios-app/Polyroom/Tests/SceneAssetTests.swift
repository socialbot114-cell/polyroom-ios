import XCTest
@testable import Polyroom

#if canImport(SceneKit)
import SceneKit

final class SceneAssetTests: XCTestCase {
    func testOpenUSDZWithSceneKit() throws {
        // SwiftPM test runs on the macOS host; load a real catalog USDZ by URL
        // so this validates Apple's importer even when no Simulator runtime is installed.
        let testsDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let repoRoot = testsDir
            .deletingLastPathComponent() // Polyroom package
            .deletingLastPathComponent() // ios-app
            .deletingLastPathComponent() // repo
        let asset = repoRoot.appendingPathComponent("art-ios/liv_moveis_sofa.usdz")
        XCTAssertTrue(FileManager.default.fileExists(atPath: asset.path), asset.path)

        let scene = try SCNScene(url: asset, options: nil)
        var hasGeometry = false
        scene.rootNode.enumerateChildNodes { node, stop in
            if node.geometry != nil {
                hasGeometry = true
                stop.pointee = true
            }
        }
        XCTAssertTrue(hasGeometry, "SceneKit deve importar a geometria do USDZ real")

        let (minimum, maximum) = scene.rootNode.boundingBox
        XCTAssertGreaterThan(maximum.x - minimum.x, 0.1)
        XCTAssertGreaterThan(maximum.y - minimum.y, 0.1)
    }
}
#endif
