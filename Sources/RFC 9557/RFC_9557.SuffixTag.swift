// RFC_9557.Suffix.Tag.swift
// swift-rfc-9557

public import ASCII_Serializer_Primitives

extension RFC_9557.Suffix {
    /// RFC 9557 suffix tag (key-value pair)
    ///
    /// Represents a tagged annotation in the suffix.
    ///
    /// ## RFC 9557 Format
    ///
    /// ```
    /// suffix-tag = "[" critical-flag suffix-key "=" suffix-value *("-" suffix-value) "]"
    /// ```
    ///
    /// ## Rules
    ///
    /// - Keys must be lowercase
    /// - Keys starting with `_` are experimental
    /// - Values are case-sensitive
    /// - Multiple values separated by hyphens
    ///
    /// ## Example
    ///
    /// ```swift
    /// let tag = try RFC_9557.Suffix.Tag(key: "u-ca", values: ["hebrew"], critical: false)
    /// print(String(tag))  // "[u-ca=hebrew]"
    /// ```
    public struct Tag: Sendable, Codable {
        /// Tag key (lowercase)
        public let key: String

        /// Tag values (case-sensitive)
        public let values: [String]

        /// Whether this tag is critical
        public let critical: Bool

        /// Creates a tag WITHOUT validation
        init(__unchecked: Void, key: String, values: [String], critical: Bool) {
            self.key = key
            self.values = values
            self.critical = critical
        }

        /// Creates a validated suffix tag
        ///
        /// - Parameters:
        ///   - key: Tag key (must be lowercase, start with letter/underscore)
        ///   - values: Tag values (must be alphanumeric)
        ///   - critical: Whether receiver must process this tag
        /// - Throws: `Error` if validation fails
        public init(key: String, values: [String], critical: Bool) throws(Error) {
            guard !key.isEmpty else {
                throw Error.emptyKey
            }

            do {
                try RFC_9557.Validation.validateSuffixKey(key)
            } catch {
                throw Error.invalidKey(key)
            }

            guard !values.isEmpty else {
                throw Error.emptyValues
            }

            for value in values {
                guard !value.isEmpty else {
                    throw Error.invalidValue("")
                }
                do {
                    try RFC_9557.Validation.validateSuffixValue(value)
                } catch {
                    throw Error.invalidValue(value)
                }
            }

            self.init(__unchecked: (), key: key, values: values, critical: critical)
        }

        /// Whether this is an experimental tag (key starts with underscore)
        public var isExperimental: Bool {
            key.hasPrefix("_")
        }
    }
}

// MARK: - Error

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

// MARK: - Hashable

extension RFC_9557.Suffix.Tag: Hashable {}

// MARK: - Binary.ASCII.Serializable

extension RFC_9557.Suffix.Tag: Binary.ASCII.Serializable {
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii tag: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        buffer.append(UInt8.ascii.leftSquareBracket)
        if tag.critical {
            buffer.append(UInt8.ascii.exclamationPoint)
        }
        buffer.append(contentsOf: tag.key.utf8)
        buffer.append(UInt8.ascii.equalsSign)
        var first = true
        for value in tag.values {
            if !first {
                buffer.append(UInt8.ascii.hyphen)
            }
            buffer.append(contentsOf: value.utf8)
            first = false
        }
        buffer.append(UInt8.ascii.rightSquareBracket)
    }

    /// Parses a suffix tag from ASCII bytes
    ///
    /// - Parameter bytes: ASCII bytes (should be "[key=value]" format)
    /// - Throws: `Error` if format is invalid
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else {
            throw Error.emptyKey
        }

        let arr = Array(bytes)

        // Find key=value part (skip brackets if present)
        var startIdx = 0
        var endIdx = arr.count

        if arr.first == UInt8.ascii.leftSquareBracket {
            startIdx = 1
        }
        if arr.last == UInt8.ascii.rightSquareBracket {
            endIdx = arr.count - 1
        }

        guard startIdx < endIdx else {
            throw Error.emptyKey
        }

        let content = arr[startIdx..<endIdx]
        guard !content.isEmpty else {
            throw Error.emptyKey
        }

        // Check critical flag
        let firstByte = content.first!
        let critical = firstByte == UInt8.ascii.exclamationPoint
        let actualStart = critical ? startIdx + 1 : startIdx
        let actualContent = arr[actualStart..<endIdx]

        // Find equals sign
        var equalsIdx: Int? = nil
        for i in actualContent.indices {
            if actualContent[i] == UInt8.ascii.equalsSign {
                equalsIdx = i
                break
            }
        }

        guard let eqIdx = equalsIdx else {
            throw Error.emptyKey
        }

        let keyBytes = actualContent[actualStart..<eqIdx]
        let valueBytes = actualContent[(eqIdx + 1)..<endIdx]

        guard !keyBytes.isEmpty else {
            throw Error.emptyKey
        }

        let key = String(decoding: keyBytes, as: UTF8.self)
        let vArr = Array(valueBytes)
        var values: [String] = []
        var vStart = 0
        for vi in 0..<vArr.count {
            if vArr[vi] == 0x2D {  // '-'
                values.append(String(decoding: vArr[vStart..<vi], as: UTF8.self))
                vStart = vi &+ 1
            }
        }
        values.append(String(decoding: vArr[vStart..<vArr.count], as: UTF8.self))

        try self.init(key: key, values: values, critical: critical)
    }
}

extension RFC_9557.Suffix.Tag: Binary.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_9557.Suffix.Tag: CustomStringConvertible {}
