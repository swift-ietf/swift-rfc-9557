public import ASCII_Serializer_Primitives

extension RFC_9557 {

    public enum Validation {}
}

extension RFC_9557.Validation {

    public static func validateSuffixKey(_ key: String) throws(ValidationError) {
        try validateSuffixKey([Byte](key.utf8))
    }

    @inlinable
    public static func validateSuffixKey<Bytes: Swift.Collection>(
        _ bytes: Bytes
    ) throws(ValidationError)
    where Bytes.Element == Byte {
        guard let first = bytes.first else {
            throw ValidationError.invalidSuffixKey
        }

        let firstCode: ASCII.Code
        do throws(ASCII.Code.Error) {
            firstCode = try ASCII.Code(first)
        } catch {
            throw ValidationError.invalidSuffixKey
        }
        guard firstCode.isLowercase || firstCode == ASCII.Code.underline else {
            throw ValidationError.invalidSuffixKey
        }

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

    @_transparent
    public static func isExperimentalKey(_ key: String) -> Bool {
        key.hasPrefix("_")
    }

    @_transparent
    public static func isExperimentalKey<Bytes: Swift.Collection>(_ bytes: Bytes) -> Bool
    where Bytes.Element == Byte {
        bytes.first.map { $0 == ASCII.Code.underline.byte } ?? false
    }
}

extension RFC_9557.Validation {

    public static func validateSuffixValue(_ value: String) throws(ValidationError) {
        try validateSuffixValue([Byte](value.utf8))
    }

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

extension RFC_9557.Validation {

    public static func validateTimeZoneName(_ name: String) throws(ValidationError) {
        try validateTimeZoneName([Byte](name.utf8))
    }

    @inlinable
    public static func validateTimeZoneName<Bytes: Swift.Collection>(
        _ bytes: Bytes
    ) throws(ValidationError)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw ValidationError.invalidTimeZoneName
        }

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

                let valid =
                    code.isLetter || code.isDigit || code == ASCII.Code.period
                    || code == ASCII.Code.underline || code == ASCII.Code.hyphen
                    || code == ASCII.Code.plus
                guard valid else {
                    throw ValidationError.invalidTimeZoneName
                }
            }
        }

        if allDots && partLength > 0 && partLength <= 2 {
            throw ValidationError.invalidTimeZoneName
        }
    }
}

extension RFC_9557.Validation {

    public static let registeredKeys: Set<String> = ["u-ca"]

    @_transparent
    public static func isRegisteredKey(_ key: String) -> Bool {
        registeredKeys.contains(key)
    }
}
