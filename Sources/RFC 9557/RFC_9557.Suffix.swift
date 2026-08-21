public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

extension RFC_9557 {

    public struct Suffix: Sendable, Codable {

        public let timeZone: TimeZone?

        public let calendar: String?

        public let tags: [Suffix.Tag]

        private init(__unchecked: Void, timeZone: TimeZone?, calendar: String?, tags: [Suffix.Tag])
        {
            self.timeZone = timeZone
            self.calendar = calendar
            self.tags = tags
        }

        public init(timeZone: TimeZone? = nil, calendar: String? = nil, tags: [Suffix.Tag] = []) {

            self.init(__unchecked: (), timeZone: timeZone, calendar: calendar, tags: tags)
        }
    }
}

extension RFC_9557.Suffix: Hashable {}

extension RFC_9557.Suffix: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {

        if let tz = value.timeZone {
            buffer.append(ASCII.Code.leftSquareBracket)
            if tz.isCritical {
                buffer.append(ASCII.Code.exclamationPoint)
            }
            buffer.append(contentsOf: tz.identifier.utf8.map { ASCII.Code(unchecked: Byte($0)) })
            buffer.append(ASCII.Code.rightSquareBracket)
        }

        if let cal = value.calendar {
            buffer.append(ASCII.Code.leftSquareBracket)
            buffer.append(contentsOf: "u-ca".utf8.map { ASCII.Code(unchecked: Byte($0)) })
            buffer.append(ASCII.Code.equalsSign)
            buffer.append(contentsOf: cal.utf8.map { ASCII.Code(unchecked: Byte($0)) })
            buffer.append(ASCII.Code.rightSquareBracket)
        }

        for tag in value.tags {
            RFC_9557.Suffix.Tag.serialize(tag, into: &buffer)
        }
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ suffix: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {

        if let tz = suffix.timeZone {
            buffer.append(ASCII.Code.leftSquareBracket)
            if tz.isCritical {
                buffer.append(ASCII.Code.exclamationPoint)
            }
            buffer.append(contentsOf: tz.identifier.utf8)
            buffer.append(ASCII.Code.rightSquareBracket)
        }

        if let cal = suffix.calendar {
            buffer.append(ASCII.Code.leftSquareBracket)
            buffer.append(contentsOf: "u-ca".utf8)
            buffer.append(ASCII.Code.equalsSign)
            buffer.append(contentsOf: cal.utf8)
            buffer.append(ASCII.Code.rightSquareBracket)
        }

        for tag in suffix.tags {
            RFC_9557.Suffix.Tag.serialize(tag, into: &buffer)
        }
    }
}

extension RFC_9557.Suffix: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        var timeZone: RFC_9557.TimeZone? = nil
        var calendar: String? = nil
        var tags: [RFC_9557.Suffix.Tag] = []
        var seenKeys = Set<String>()

        var index = bytes.startIndex
        while index < bytes.endIndex {

            guard bytes[index] == ASCII.Code.leftSquareBracket.byte else {
                index = bytes.index(after: index)
                continue
            }

            let contentStart = bytes.index(after: index)

            var bracketEnd: Bytes.Index? = nil
            var searchIndex = contentStart
            while searchIndex < bytes.endIndex {
                if bytes[searchIndex] == ASCII.Code.rightSquareBracket.byte {
                    bracketEnd = searchIndex
                    break
                }
                searchIndex = bytes.index(after: searchIndex)
            }

            guard let end = bracketEnd else {
                throw Error.malformedBrackets(String(decoding: bytes, as: UTF8.self))
            }

            let content = bytes[contentStart..<end]
            guard !content.isEmpty else {
                throw Error.emptyTag
            }

            let firstByte = content.first!
            let critical = firstByte == ASCII.Code.exclamationPoint.byte
            let actualContent: Bytes.SubSequence
            if critical {
                let afterBang = content.index(after: content.startIndex)
                guard afterBang < content.endIndex else {
                    throw Error.emptyTag
                }
                actualContent = content[afterBang...]
            } else {
                actualContent = content
            }

            guard !actualContent.isEmpty else {
                throw Error.emptyTag
            }

            var hasEquals = false
            var equalsIndex: Bytes.Index? = nil
            for i in actualContent.indices {
                if actualContent[i] == ASCII.Code.equalsSign.byte {
                    hasEquals = true
                    equalsIndex = i
                    break
                }
            }

            if hasEquals, let eqIdx = equalsIndex {

                let keyBytes = actualContent[..<eqIdx]
                let valueBytes = actualContent[actualContent.index(after: eqIdx)...]

                guard !keyBytes.isEmpty else {
                    throw Error.invalidKey("")
                }
                guard !valueBytes.isEmpty else {
                    throw Error.invalidValue("")
                }

                let key = String(decoding: keyBytes, as: UTF8.self)

                do throws(RFC_9557.Validation.ValidationError) {
                    try RFC_9557.Validation.validateSuffixKey(key)
                } catch {
                    throw Error.invalidKey(key)
                }

                if RFC_9557.Validation.isExperimentalKey(key) {
                    if critical {
                        throw Error.criticalExperimentalTag(key)
                    }
                    throw Error.experimentalTagInInterchange(key)
                }

                let vBytes = Array(valueBytes)
                var values: [String] = []
                var vStart = 0
                vBytes.indices.forEach { vi in
                    if vBytes[vi] == ASCII.Code.hyphen.byte {
                        values.append(String(decoding: vBytes[vStart..<vi], as: UTF8.self))
                        vStart = vi &+ 1
                    }
                }
                values.append(String(decoding: vBytes[vStart..<vBytes.count], as: UTF8.self))

                for value in values {
                    do throws(RFC_9557.Validation.ValidationError) {
                        try RFC_9557.Validation.validateSuffixValue(value)
                    } catch {
                        throw Error.invalidValue(value)
                    }
                }

                if key == "u-ca" {
                    if calendar == nil {
                        calendar = values.first
                    }

                } else {

                    if critical && !RFC_9557.Validation.isRegisteredKey(key) {
                        throw Error.criticalTagNotSupported(key)
                    }

                    if !seenKeys.contains(key) {
                        tags.append(
                            RFC_9557.Suffix.Tag(

                                __unchecked: (),
                                key: key,
                                values: values,
                                critical: critical
                            )
                        )
                        seenKeys.insert(key)
                    }
                }
            } else {

                guard timeZone == nil else {
                    throw Error.multipleTimeZones
                }

                let tzString = String(decoding: actualContent, as: UTF8.self)

                let firstCharByte = actualContent[actualContent.startIndex]
                if firstCharByte == ASCII.Code.plus.byte
                    || firstCharByte == ASCII.Code.hyphen.byte
                {
                    timeZone = .offset(tzString, critical: critical)
                } else {
                    do throws(RFC_9557.Validation.ValidationError) {
                        try RFC_9557.Validation.validateTimeZoneName(tzString)
                    } catch {
                        throw Error.invalidTimeZoneName(tzString)
                    }
                    timeZone = .iana(tzString, critical: critical)
                }
            }

            index = bytes.index(after: end)
        }

        self.init(__unchecked: (), timeZone: timeZone, calendar: calendar, tags: tags)
    }
}

extension RFC_9557.Suffix: Swift.RawRepresentable {
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

extension RFC_9557.Suffix: CustomStringConvertible {

    public var description: String {
        String(decoding: serialized.underlying, as: UTF8.self)
    }
}

extension RFC_9557.Suffix {

    public var hasCriticalComponents: Bool {
        if timeZone?.isCritical == true {
            return true
        }
        return tags.contains { $0.critical }
    }
}
