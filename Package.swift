// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-9557",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "RFC 9557", targets: ["RFC 9557"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-standard-library-extensions.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-ietf/swift-rfc-3339.git", branch: "main"),
        .package(
            url: "https://github.com/swift-atoms/swift-parser.git",
            branch: "main", traits: ["Append", "IteratorLeaves", "Map", "Product", "Skip", "Either", "Iterator"]
        ),
        .package(url: "https://github.com/swift-atoms/swift-ascii.git", branch: "main", traits: ["Parser", "Serializer"]),
        .package(url: "https://github.com/swift-atoms/swift-binary.git", branch: "main", traits: ["Serializer"]),
    ],
    targets: [
        .target(
            name: "RFC 9557",
            dependencies: [
                .product(
                    name: "Standard Library Extensions",
                    package: "swift-standard-library-extensions"
                ),
                .product(name: "RFC 3339", package: "swift-rfc-3339"),
                .product(name: "Parser", package: "swift-parser"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Binary", package: "swift-binary"),
            ]
        ),
        .testTarget(
            name: "RFC 9557 Tests",
            dependencies: [
                .target(name: "RFC 9557"),
                .product(name: "Binary", package: "swift-binary"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
