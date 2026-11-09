// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacDraw",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "MacDraw", targets: ["MacDraw"])],
    targets: [
        .target(name: "DrawingCore"),
        .executableTarget(name: "MacDraw", dependencies: ["DrawingCore"]),
        .executableTarget(name: "DrawingCoreChecks", dependencies: ["DrawingCore"], path: "Tests/DrawingCoreTests")
    ],
    swiftLanguageModes: [.v5]
)
