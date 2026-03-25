// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-rfc-9557",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(name: "RFC 9557", targets: ["RFC 9557"])
    ],
    dependencies: [
        .package(path: "../../swift-foundations/swift-ascii"),
        .package(path: "../../swift-primitives/swift-standard-library-extensions"),
        .package(path: "../swift-rfc-3339"),
        .package(path: "../../swift-primitives/swift-parser-primitives")
    ],
    targets: [
        .target(
            name: "RFC 9557",
            dependencies: [
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "RFC 3339", package: "swift-rfc-3339"),
                .product(name: "Parser Primitives", package: "swift-parser-primitives")
            ]
        ),
        .testTarget(
            name: "RFC 9557 Tests",
            dependencies: [
                "RFC 9557",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
