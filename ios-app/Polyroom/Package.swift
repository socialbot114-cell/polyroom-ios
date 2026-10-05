// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "Polyroom",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Polyroom", targets: ["Polyroom"])],
    targets: [
        .target(name: "Polyroom", path: "Sources"),
        .testTarget(name: "PolyroomTests", dependencies: ["Polyroom"], path: "Tests")
    ]
)
