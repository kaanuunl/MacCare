// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacCare",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MacCare", targets: ["MacCare"])
    ],
    targets: [
        .executableTarget(name: "MacCare")
    ],
    swiftLanguageModes: [.v5]
)
