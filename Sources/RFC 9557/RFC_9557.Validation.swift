// RFC_9557.Validation.swift
// swift-rfc-9557

public import ASCII_Serializer_Primitives

extension RFC_9557 {
    /// Validation rules for RFC 9557 components
    ///
    /// Implements format validation per RFC 9557 ABNF grammar.
    ///
    /// ## Authoritative Implementation
    ///
    /// All validation functions in this enum are authoritative.
    /// Other code should delegate to these functions.
    public enum Validation {}
}

// MARK: - Suffix Key Validation

extension RFC_9557.Validation {
    /// Validate suffix key format
    ///
    /// Per RFC 9557 ABNF:
    /// ```
    /// suffix-key = key-initial *key-char
    /// key-initial = lcalpha / "_"
    /// key-char = key-initial / DIGIT / "-"
    /// ```
    ///
    /// - Parameter key: Suffix key to validate
    /// - Throws: Error if format is invalid
    public static func validateSuffixKey(_ key: String) throws(ValidationError) {
        try validateSuffixKey(Array(key.utf8))
    }

    /// Validate suffix key from bytes (authoritative)
    @inlinable
    public static func validateSuffixKey<Bytes: Collection>(_ bytes: Bytes) throws(ValidationError)
    where Bytes.Element == UInt8 {
        guard let first = bytes.first else {
            throw ValidationError.invalidSuffixKey
        }

        // First character: lowercase letter or underscore
        guard first.ascii.isLowercase || first == UInt8.ascii.underline else {
            throw ValidationError.invalidSuffixKey
        }

        // Remaining: lowercase letters, digits, hyphens, underscores
        for byte in bytes {
            let valid =
                byte.ascii.isLowercase || byte.ascii.isDigit || byte == UInt8.ascii.hyphen
                || byte == UInt8.ascii.underline
            guard valid else {
                throw ValidationError.invalidSuffixKey
            }
        }
    }

    /// Check if key is experimental (starts with underscore)
    @_transparent
    public static func isExperimentalKey(_ key: String) -> Bool {
        key.hasPrefix("_")
    }

    /// Check if key is experimental (byte version)
    @_transparent
    public static func isExperimentalKey<Bytes: Collection>(_ bytes: Bytes) -> Bool
    where Bytes.Element == UInt8 {
        bytes.first == UInt8.ascii.underline
    }
}

// MARK: - Suffix Value Validation

extension RFC_9557.Validation {
    /// Validate suffix value format
    ///
    /// Per RFC 9557 ABNF:
    /// ```
    /// suffix-value = 1*alphanum
    /// alphanum = ALPHA / DIGIT
    /// ```
    ///
    /// - Parameter value: Suffix value to validate
    /// - Throws: Error if format is invalid
    public static func validateSuffixValue(_ value: String) throws(ValidationError) {
        try validateSuffixValue(Array(value.utf8))
    }

    /// Validate suffix value from bytes (authoritative)
    @inlinable
    public static func validateSuffixValue<Bytes: Collection>(_ bytes: Bytes) throws(ValidationError)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else {
            throw ValidationError.invalidSuffixValue
        }

        for byte in bytes {
            guard byte.ascii.isLetter || byte.ascii.isDigit else {
                throw ValidationError.invalidSuffixValue
            }
        }
    }
}

// MARK: - Time Zone Name Validation

extension RFC_9557.Validation {
    /// Validate time zone name format
    ///
    /// Per RFC 9557:
    /// - Alphanumeric characters, dots, underscores, hyphens, plus signs, forward slashes
    /// - Parts separated by "/" cannot be "." or ".."
    ///
    /// - Parameter name: Time zone name to validate
    /// - Throws: Error if format is invalid
    public static func validateTimeZoneName(_ name: String) throws(ValidationError) {
        try validateTimeZoneName(Array(name.utf8))
    }

    /// Validate time zone name from bytes (authoritative)
    @inlinable
    public static func validateTimeZoneName<Bytes: Collection>(_ bytes: Bytes) throws(ValidationError)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else {
            throw ValidationError.invalidTimeZoneName
        }

        // Check for ".." or single "." parts
        var partStart = bytes.startIndex
        var partLength = 0
        var allDots = true

        for index in bytes.indices {
            let byte = bytes[index]

            if byte == UInt8.ascii.solidus {
                // End of part - check if it's "." or ".."
                if allDots && partLength > 0 && partLength <= 2 {
                    throw ValidationError.invalidTimeZoneName
                }
                partStart = bytes.index(after: index)
                partLength = 0
                allDots = true
            } else {
                partLength += 1
                if byte != UInt8.ascii.period {
                    allDots = false
                }

                // Validate character
                let valid =
                    byte.ascii.isLetter || byte.ascii.isDigit || byte == UInt8.ascii.period
                    || byte == UInt8.ascii.underline || byte == UInt8.ascii.hyphen
                    || byte == UInt8.ascii.plus
                guard valid else {
                    throw ValidationError.invalidTimeZoneName
                }
            }
        }

        // Check final part
        if allDots && partLength > 0 && partLength <= 2 {
            throw ValidationError.invalidTimeZoneName
        }
    }
}

// MARK: - Registered Keys

extension RFC_9557.Validation {
    /// Registered suffix keys per IANA registry
    public static let registeredKeys: Set<String> = ["u-ca"]

    /// Check if a suffix key is registered
    @_transparent
    public static func isRegisteredKey(_ key: String) -> Bool {
        registeredKeys.contains(key)
    }
}

// MARK: - Validation Error

extension RFC_9557.Validation {
    /// Internal validation errors
    public enum ValidationError: Swift.Error, Sendable {
        case invalidSuffixKey
        case invalidSuffixValue
        case invalidTimeZoneName
    }
}
