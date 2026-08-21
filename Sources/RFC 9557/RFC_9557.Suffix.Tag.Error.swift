extension RFC_9557.Suffix.Tag {

    public enum Error: Swift.Error, Sendable, Equatable {

        case emptyKey

        case invalidKey(_ key: String)

        case emptyValues

        case invalidValue(_ value: String)
    }
}

extension RFC_9557.Suffix.Tag.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyKey:
            return "Tag key cannot be empty"

        case .invalidKey(let key):
            return "Invalid tag key '\(key)'"

        case .emptyValues:
            return "Tag must have at least one value"

        case .invalidValue(let value):
            return "Invalid tag value '\(value)'"
        }
    }
}
