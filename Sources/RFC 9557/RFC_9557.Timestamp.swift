public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

extension RFC_9557 {

    public struct Timestamp: Sendable, Codable {

        public let base: RFC_3339.DateTime

        public let suffix: Suffix?

        private init(__unchecked: Void, base: RFC_3339.DateTime, suffix: Suffix?) {
            self.base = base
            self.suffix = suffix
        }

        public init(base: RFC_3339.DateTime, suffix: Suffix? = nil) {

            self.init(__unchecked: (), base: base, suffix: suffix)
        }
    }
}

extension RFC_9557.Timestamp: Hashable {}

extension RFC_9557.Timestamp: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        RFC_3339.DateTime.serialize(value.base, into: &buffer)
        if let suffix = value.suffix {
            RFC_9557.Suffix.serialize(suffix, into: &buffer)
        }
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

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

extension RFC_9557.Timestamp: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        let bracketIndex: Bytes.Index? = bytes.indices.first { index in
            bytes[index] == ASCII.Code.leftSquareBracket.byte
        }

        if let bracketIndex {

            let basePart = bytes[..<bracketIndex]
            let suffixPart = bytes[bracketIndex...]

            let base: RFC_3339.DateTime
            do throws(RFC_3339.DateTime.Error) {
                base = try RFC_3339.DateTime(ascii: basePart)
            } catch {
                throw Error.invalidBase(String(decoding: basePart, as: UTF8.self))
            }

            let suffix: RFC_9557.Suffix
            do throws(RFC_9557.Suffix.Error) {
                suffix = try RFC_9557.Suffix(ascii: suffixPart)
            } catch {
                throw Error.invalidSuffix(error)
            }

            self.init(__unchecked: (), base: base, suffix: suffix)
        } else {

            let base: RFC_3339.DateTime
            do throws(RFC_3339.DateTime.Error) {
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

    public var rawValue: String {
        String(decoding: serialized.underlying, as: UTF8.self)
    }

    public init?(rawValue: String) {
        do throws(Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }
}

extension RFC_9557.Timestamp: CustomStringConvertible {

    public var description: String {
        String(decoding: serialized.underlying, as: UTF8.self)
    }
}
