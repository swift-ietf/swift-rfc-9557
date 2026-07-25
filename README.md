# swift-rfc-9557

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

The IXDTF timestamp extension carrying time zone and tags, defined in RFC 9557.

## Standard Reference

- **RFC**: 9557
- **Title**: Date and Time on the Internet: Timestamps with Additional Information

## Installation

Add the package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/swift-ietf/swift-rfc-9557.git", from: "0.1.5")
]
```

Add the product to a target that needs it:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RFC 9557", package: "swift-rfc-9557")
    ]
)
```

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
