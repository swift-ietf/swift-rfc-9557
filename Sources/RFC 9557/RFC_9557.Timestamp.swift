// RFC_9557.Timestamp.swift
// swift-rfc-9557

public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

extension RFC_9557 {
    /// RFC 9557 extended timestamp
    ///
    /// Combines an RFC 3339 timestamp with optional suffix annotations.
    ///
    /// ## RFC 9557 Format
    ///
    /// ```
    /// date-time-ext = date-time suffix
    /// suffix        = [time-zone] *suffix-tag
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Parse extended timestamp
    /// let ts = try RFC_9557.Timestamp("1996-12-19T16:39:57-08:00[America/Los_Angeles]")
    ///
    /// // Access base timestamp
    /// print(ts.base.time.year)  // 1996
    ///
    /// // Access suffix
    /// if let tz = ts.suffix?.timeZone {
    ///     print(tz.identifier)  // "America/Los_Angeles"
    /// }
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``Suffix``
    /// - ``RFC_3339/DateTime``
    public struct Timestamp: Sendable, Codable {
        /// RFC 3339 base timestamp
        public let base: RFC_3339.DateTime

        /// Optional suffix annotations
        public let suffix: Suffix?

        /// Creates a timestamp WITHOUT validation
        ///
        /// Private to ensure all public construction goes through validation.
        private init(__unchecked: Void, base: RFC_3339.DateTime, suffix: Suffix?) {
            self.base = base
            self.suffix = suffix
        }

        /// Creates an extended timestamp with validation
        ///
        /// - Parameters:
        ///   - base: RFC 3339 timestamp
        ///   - suffix: Optional suffix annotations
        public init(base: RFC_3339.DateTime, suffix: Suffix? = nil) {
            self.init(__unchecked: (), base: base, suffix: suffix)
        }
    }
}

// MARK: - Hashable

extension RFC_9557.Timestamp: Hashable {}

// MARK: - Serializable

extension RFC_9557.Timestamp: ASCII.Serializable, Binary.Serializable {
    /// Own `ASCII.Serializable` verb ([FAM-012]) — the RFC 9557 extended timestamp:
    /// the RFC 3339 base date-time followed by the optional suffix, each composed via
    /// its re-cut sub-part verb directly into the `ASCII.Code` buffer.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        RFC_3339.DateTime.serialize(value.base, into: &buffer)
        if let suffix = value.suffix {
            RFC_9557.Suffix.serialize(suffix, into: &buffer)
        }
    }

    /// Explicit `Binary.Serializable` witness disambiguating the two
    /// constraint-incomparable `serialize(_:into:)` defaults.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    /// Byte-domain serialization body ([FAM-012] clause 9 — composes the same
    /// sub-part verbs as the ASCII verb): the base (rfc-3339 DateTime) and the
    /// optional suffix compose their re-cut `serialize(_:into:)` verbs directly.
    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ timestamp: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        RFC_3339.DateTime.serialize(timestamp.base, into: &buffer)
        if let suffix = timestamp.suffix {
            RFC_9557.Suffix.serialize(suffix, into: &buffer)
        }
    }
}

// MARK: - Parseable

extension RFC_9557.Timestamp: ASCII.Parseable {
    /// Creates an extended timestamp by validating `string`'s UTF-8 bytes.
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    /// Parses an extended timestamp from ASCII bytes
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [Byte] (ASCII bytes)
    /// - **Codomain**: RFC_9557.Timestamp (structured data)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array<Byte>("1996-12-19T16:39:57-08:00[America/Los_Angeles]".utf8)
    /// let ts = try RFC_9557.Timestamp(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: ASCII byte representation
    /// - Throws: `Error` if format is invalid
    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        // Find where RFC 3339 part ends (first '[' or end)
        var bracketIndex: Bytes.Index? = nil
        for index in bytes.indices {
            if (try? ASCII.Code(bytes[index])) == ASCII.Code.leftSquareBracket {
                bracketIndex = index
                break
            }
        }

        if let bracketIndex = bracketIndex {
            // Has suffix - split and parse
            let basePart = bytes[..<bracketIndex]
            let suffixPart = bytes[bracketIndex...]

            let base: RFC_3339.DateTime
            do {
                base = try RFC_3339.DateTime(ascii: basePart)
            } catch {
                throw Error.invalidBase(String(decoding: basePart, as: UTF8.self))
            }

            let suffix: RFC_9557.Suffix
            do {
                suffix = try RFC_9557.Suffix(ascii: suffixPart)
            } catch let error as RFC_9557.Suffix.Error {
                throw Error.invalidSuffix(error)
            } catch {
                throw Error.invalidSuffix(
                    .malformedBrackets(String(decoding: suffixPart, as: UTF8.self))
                )
            }

            self.init(__unchecked: (), base: base, suffix: suffix)
        } else {
            // No suffix - parse as plain RFC 3339
            let base: RFC_3339.DateTime
            do {
                base = try RFC_3339.DateTime(ascii: bytes)
            } catch {
                throw Error.invalidBase(String(decoding: bytes, as: UTF8.self))
            }

            self.init(__unchecked: (), base: base, suffix: nil)
        }
    }
}

extension RFC_9557.Timestamp: Swift.RawRepresentable {
    public typealias RawValue = String

    /// The timestamp's ASCII serialization as a `String` (computed; derived
    /// from serialization, not stored).
    public var rawValue: String {
        String(decoding: serialized.underlying, as: UTF8.self)
    }

    public init?(rawValue: String) { try? self.init(rawValue) }
}

extension RFC_9557.Timestamp: CustomStringConvertible {
    /// The timestamp's ASCII serialization decoded as a `String`.
    public var description: String {
        String(decoding: serialized.underlying, as: UTF8.self)
    }
}
