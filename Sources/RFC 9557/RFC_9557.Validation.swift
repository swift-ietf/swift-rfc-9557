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
        try validateSuffixKey([Byte](key.utf8))
    }

    /// Validate suffix key from bytes (authoritative)
    @inlinable
    public static func validateSuffixKey<Bytes: Swift.Collection>(
        _ bytes: Bytes
    ) throws(ValidationError)
    where Bytes.Element == Byte {
        guard let first = bytes.first else {
            throw ValidationError.invalidSuffixKey
        }

        // First character: lowercase letter or underscore
        let firstCode: ASCII.Code
        do throws(ASCII.Code.Error) {
            firstCode = try ASCII.Code(first)
        } catch {
            throw ValidationError.invalidSuffixKey
        }
        guard firstCode.isLowercase || firstCode == ASCII.Code.underline else {
            throw ValidationError.invalidSuffixKey
        }

        // Remaining: lowercase letters, digits, hyphens, underscores
        for byte in bytes {
            let code: ASCII.Code
            do throws(ASCII.Code.Error) {
                code = try ASCII.Code(byte)
            } catch {
                throw ValidationError.invalidSuffixKey
            }
            let valid =
                code.isLowercase || code.isDigit || code == ASCII.Code.hyphen
                || code == ASCII.Code.underline
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
    public static func isExperimentalKey<Bytes: Swift.Collection>(_ bytes: Bytes) -> Bool
    where Bytes.Element == Byte {
        bytes.first.map { $0 == ASCII.Code.underline.byte } ?? false
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
        try validateSuffixValue([Byte](value.utf8))
    }

    /// Validate suffix value from bytes (authoritative)
    @inlinable
    public static func validateSuffixValue<Bytes: Swift.Collection>(
        _ bytes: Bytes
    ) throws(ValidationError)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw ValidationError.invalidSuffixValue
        }

        for byte in bytes {
            let code: ASCII.Code
            do throws(ASCII.Code.Error) {
                code = try ASCII.Code(byte)
            } catch {
                throw ValidationError.invalidSuffixValue
            }
            guard code.isLetter || code.isDigit else {
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
        try validateTimeZoneName([Byte](name.utf8))
    }

    /// Validate time zone name from bytes (authoritative)
    @inlinable
    public static func validateTimeZoneName<Bytes: Swift.Collection>(
        _ bytes: Bytes
    ) throws(ValidationError)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw ValidationError.invalidTimeZoneName
        }

        // Check for ".." or single "." parts
        var partStart = bytes.startIndex
        var partLength = 0
        var allDots = true

        for index in bytes.indices {
            let byte = bytes[index]
            let code: ASCII.Code
            do throws(ASCII.Code.Error) {
                code = try ASCII.Code(byte)
            } catch {
                throw ValidationError.invalidTimeZoneName
            }

            if code == ASCII.Code.solidus {
                // End of part - check if it's "." or ".."
                if allDots && partLength > 0 && partLength <= 2 {
                    throw ValidationError.invalidTimeZoneName
                }
                partStart = bytes.index(after: index)
                partLength = 0
                allDots = true
            } else {
                partLength += 1
                if code != ASCII.Code.period {
                    allDots = false
                }

                // Validate character
                let valid =
                    code.isLetter || code.isDigit || code == ASCII.Code.period
                    || code == ASCII.Code.underline || code == ASCII.Code.hyphen
                    || code == ASCII.Code.plus
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
