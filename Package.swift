// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "SQLiteKit",
    platforms: [
        .macOS(.v12), .iOS(.v15), .tvOS(.v15), .visionOS(.v1)
    ],
    products: [
        .library(name: "SQLiteKit", targets: ["SQLiteKit"])
    ],
    dependencies: [],
    targets: [
        .target(name: "SQLiteKit", dependencies: ["libsqlite3"]),
        .systemLibrary(name: "libsqlite3"),
        .testTarget(name: "SQLiteKitTests", dependencies: ["SQLiteKit"])
    ]
)
