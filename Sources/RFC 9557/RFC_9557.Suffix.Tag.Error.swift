extension RFC_9557.Suffix.Tag {
    /// Errors that can occur during tag validation
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Key is empty
        case emptyKey

        /// Key format is invalid
        case invalidKey(_ key: String)

        /// Values array is empty
        case emptyValues

        /// Value format is invalid
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
