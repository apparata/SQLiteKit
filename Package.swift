// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "SQLiteKit",
    platforms: [
        .macOS(.v10_14), .iOS(.v12), .tvOS(.v12)
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
