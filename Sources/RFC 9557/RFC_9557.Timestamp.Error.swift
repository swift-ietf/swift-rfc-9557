// RFC_9557.Timestamp.Error.swift
// swift-rfc-9557

extension RFC_9557.Timestamp {
    /// Errors that can occur during timestamp parsing
    ///
    /// These represent validation failures when parsing RFC 9557 extended timestamps.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Timestamp is empty
        case empty

        /// Base RFC 3339 timestamp is invalid
        case invalidBase(_ value: String)

        /// Suffix is invalid
        case invalidSuffix(_ error: RFC_9557.Suffix.Error)
    }
}

extension RFC_9557.Timestamp.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Timestamp cannot be empty"

        case .invalidBase(let value):
            return "Invalid RFC 3339 base timestamp: '\(value)'"

        case .invalidSuffix(let error):
            return "Invalid suffix: \(error)"
        }
    }
}
