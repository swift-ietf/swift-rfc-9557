extension RFC_9557.Suffix {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case malformedBrackets(_ value: String)

        case emptyTag

        case multipleTimeZones

        case invalidKey(_ key: String)

        case invalidValue(_ value: String)

        case invalidTimeZoneName(_ name: String)

        case criticalTagNotSupported(_ key: String)

        case criticalExperimentalTag(_ key: String)

        case experimentalTagInInterchange(_ key: String)
    }
}

extension RFC_9557.Suffix.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Suffix cannot be empty"

        case .malformedBrackets(let value):
            return "Malformed brackets in suffix: '\(value)'"

        case .emptyTag:
            return "Empty tag content in suffix"

        case .multipleTimeZones:
            return "Multiple time zones specified (only one allowed)"

        case .invalidKey(let key):
            return "Invalid suffix key '\(key)': must be lowercase, start with letter/underscore"

        case .invalidValue(let value):
            return "Invalid suffix value '\(value)': must be alphanumeric"

        case .invalidTimeZoneName(let name):
            return "Invalid time zone name '\(name)'"

        case .criticalTagNotSupported(let key):
            return "Critical tag '\(key)' is not supported"

        case .criticalExperimentalTag(let key):
            return "Critical experimental tag '\(key)' is not allowed"

        case .experimentalTagInInterchange(let key):
            return "Experimental tag '\(key)' not allowed in interchange"
        }
    }
}
