// RFC_9557.Suffix.Error.swift
// swift-rfc-9557

extension RFC_9557.Suffix {
    /// Errors that can occur during suffix parsing
    ///
    /// Represents validation failures when parsing RFC 9557 suffix annotations.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Suffix is empty
        case empty

        /// Unmatched or malformed brackets
        case malformedBrackets(_ value: String)

        /// Empty tag content (just brackets or just "!")
        case emptyTag

        /// Multiple time zones specified (only one allowed)
        case multipleTimeZones

        /// Invalid suffix key format
        case invalidKey(_ key: String)

        /// Invalid suffix value format
        case invalidValue(_ value: String)

        /// Invalid time zone name format
        case invalidTimeZoneName(_ name: String)

        /// Critical tag with unknown key must be rejected
        case criticalTagNotSupported(_ key: String)

        /// Critical experimental tag in non-experimental context
        case criticalExperimentalTag(_ key: String)

        /// Experimental tag in interchange context
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
