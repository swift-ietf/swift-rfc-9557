public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

extension RFC_9557.Suffix {

    public struct Tag: Sendable, Codable {

        public let key: String

        public let values: [String]

        public let critical: Bool

        init(__unchecked: Void, key: String, values: [String], critical: Bool) {
            self.key = key
            self.values = values
            self.critical = critical
        }

        public init(key: String, values: [String], critical: Bool) throws(Error) {
            guard !key.isEmpty else {
                throw Error.emptyKey
            }

            do throws(RFC_9557.Validation.ValidationError) {
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
                do throws(RFC_9557.Validation.ValidationError) {
                    try RFC_9557.Validation.validateSuffixValue(value)
                } catch {
                    throw Error.invalidValue(value)
                }
            }

            self.init(__unchecked: (), key: key, values: values, critical: critical)
        }
    }
}

extension RFC_9557.Suffix.Tag {

    public var isExperimental: Bool {
        key.hasPrefix("_")
    }
}

extension RFC_9557.Suffix.Tag: Hashable {}

extension RFC_9557.Suffix.Tag: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        buffer.append(ASCII.Code.leftSquareBracket)
        if value.critical {
            buffer.append(ASCII.Code.exclamationPoint)
        }
        buffer.append(contentsOf: value.key.utf8.map { ASCII.Code(unchecked: Byte($0)) })
        buffer.append(ASCII.Code.equalsSign)
        var first = true
        for tagValue in value.values {
            if !first {
                buffer.append(ASCII.Code.hyphen)
            }
            buffer.append(contentsOf: tagValue.utf8.map { ASCII.Code(unchecked: Byte($0)) })
            first = false
        }
        buffer.append(ASCII.Code.rightSquareBracket)
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ tag: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(ASCII.Code.leftSquareBracket)
        if tag.critical {
            buffer.append(ASCII.Code.exclamationPoint)
        }
        buffer.append(contentsOf: tag.key.utf8)
        buffer.append(ASCII.Code.equalsSign)
        var first = true
        for value in tag.values {
            if !first {
                buffer.append(ASCII.Code.hyphen)
            }
            buffer.append(contentsOf: value.utf8)
            first = false
        }
        buffer.append(ASCII.Code.rightSquareBracket)
    }
}

extension RFC_9557.Suffix.Tag: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.emptyKey
        }

        let arr: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            arr = try [ASCII.Code](bytes)
        } catch {
            throw Error.invalidKey(String(decoding: bytes, as: UTF8.self))
        }

        var startIdx = 0
        var endIdx = arr.count

        if arr.first == ASCII.Code.leftSquareBracket {
            startIdx = 1
        }
        if arr.last == ASCII.Code.rightSquareBracket {
            endIdx = arr.endIndex - 1
        }

        guard startIdx < endIdx else {
            throw Error.emptyKey
        }

        let content = arr[startIdx..<endIdx]
        guard !content.isEmpty else {
            throw Error.emptyKey
        }

        let firstByte = content.first!
        let critical = firstByte == ASCII.Code.exclamationPoint
        let actualStart = critical ? startIdx + 1 : startIdx
        let actualContent = arr[actualStart..<endIdx]

        var equalsIdx: Int? = nil
        for i in actualContent.indices {
            if actualContent[i] == ASCII.Code.equalsSign {
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
        vArr.indices.forEach { vi in
            if vArr[vi] == ASCII.Code.hyphen {
                values.append(String(decoding: vArr[vStart..<vi], as: UTF8.self))
                vStart = vi &+ 1
            }
        }
        values.append(String(decoding: vArr[vStart..<vArr.count], as: UTF8.self))

        try self.init(key: key, values: values, critical: critical)
    }
}

extension RFC_9557.Suffix.Tag: Swift.RawRepresentable {
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

extension RFC_9557.Suffix.Tag: CustomStringConvertible {

    public var description: String {
        String(decoding: serialized.underlying, as: UTF8.self)
    }
}
