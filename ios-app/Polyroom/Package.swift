// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "Polyroom",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "Polyroom", targets: ["Polyroom"])],
    targets: [
        .target(
            name: "Polyroom",
            path: ".",
            sources: ["Sources"],
            resources: [.process("Resources/Sounds")]
        ),
        .testTarget(name: "PolyroomTests", dependencies: ["Polyroom"], path: "Tests")
    ]
)
