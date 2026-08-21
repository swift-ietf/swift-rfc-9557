extension RFC_9557.Timestamp {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case invalidBase(_ value: String)

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
