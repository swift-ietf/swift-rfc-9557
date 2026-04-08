// RFC_9557.Suffix.swift
// swift-rfc-9557

public import ASCII_Serializer_Primitives

extension RFC_9557 {
    /// RFC 9557 suffix annotations
    ///
    /// Contains optional metadata appended to RFC 3339 timestamps.
    ///
    /// ## RFC 9557 Format
    ///
    /// ```
    /// suffix        = [time-zone] *suffix-tag
    /// time-zone     = "[" critical-flag time-zone-char *time-zone-char "]"
    /// suffix-tag    = "[" critical-flag suffix-key "=" suffix-value *("-" suffix-value) "]"
    /// ```
    ///
    /// ## Components
    ///
    /// - **Time Zone**: IANA identifier or numeric offset
    /// - **Calendar**: Unicode calendar system identifier (u-ca)
    /// - **Custom Tags**: Additional key-value pairs
    ///
    /// ## Example
    ///
    /// ```swift
    /// let suffix = try RFC_9557.Suffix("[America/Los_Angeles][u-ca=hebrew]")
    /// print(suffix.timeZone?.identifier)  // "America/Los_Angeles"
    /// print(suffix.calendar)  // "hebrew"
    /// ```
    public struct Suffix: Sendable, Codable {
        /// Optional time zone annotation
        public let timeZone: TimeZone?

        /// Optional calendar system preference (u-ca key)
        public let calendar: String?

        /// Additional suffix tags
        public let tags: [Suffix.Tag]

        /// Creates a suffix WITHOUT validation
        private init(__unchecked: Void, timeZone: TimeZone?, calendar: String?, tags: [Suffix.Tag]) {
            self.timeZone = timeZone
            self.calendar = calendar
            self.tags = tags
        }

        /// Creates suffix with components
        ///
        /// - Parameters:
        ///   - timeZone: Optional time zone annotation
        ///   - calendar: Optional calendar system identifier
        ///   - tags: Additional suffix tags
        public init(timeZone: TimeZone? = nil, calendar: String? = nil, tags: [Suffix.Tag] = []) {
            self.init(__unchecked: (), timeZone: timeZone, calendar: calendar, tags: tags)
        }
    }
}

// MARK: - Hashable

extension RFC_9557.Suffix: Hashable {}

// MARK: - Binary.ASCII.Serializable

extension RFC_9557.Suffix: Binary.ASCII.Serializable {
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii suffix: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        // Time zone first
        if let tz = suffix.timeZone {
            buffer.append(UInt8.ascii.leftSquareBracket)
            if tz.isCritical {
                buffer.append(UInt8.ascii.exclamationPoint)
            }
            buffer.append(contentsOf: tz.identifier.utf8)
            buffer.append(UInt8.ascii.rightSquareBracket)
        }

        // Calendar
        if let cal = suffix.calendar {
            buffer.append(contentsOf: "[u-ca=".utf8)
            buffer.append(contentsOf: cal.utf8)
            buffer.append(UInt8.ascii.rightSquareBracket)
        }

        // Additional tags
        for tag in suffix.tags {
            RFC_9557.Suffix.Tag.serialize(ascii: tag, into: &buffer)
        }
    }

    /// Parses suffix from ASCII bytes
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes starting with '[')
    /// - **Codomain**: RFC_9557.Suffix (structured data)
    ///
    /// - Parameter bytes: ASCII byte representation (must start with '[')
    /// - Throws: `Error` if format is invalid
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        var timeZone: RFC_9557.TimeZone? = nil
        var calendar: String? = nil
        var tags: [RFC_9557.Suffix.Tag] = []
        var seenKeys = Set<String>()

        // Parse bracket groups
        var index = bytes.startIndex
        while index < bytes.endIndex {
            // Find opening bracket
            guard bytes[index] == UInt8.ascii.leftSquareBracket else {
                index = bytes.index(after: index)
                continue
            }

            let contentStart = bytes.index(after: index)

            // Find closing bracket
            var bracketEnd: Bytes.Index? = nil
            var searchIndex = contentStart
            while searchIndex < bytes.endIndex {
                if bytes[searchIndex] == UInt8.ascii.rightSquareBracket {
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

            // Check for critical flag
            let firstByte = content.first!
            let critical = firstByte == UInt8.ascii.exclamationPoint
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

            // Check if it's a key=value tag
            var hasEquals = false
            var equalsIndex: Bytes.Index? = nil
            for i in actualContent.indices {
                if actualContent[i] == UInt8.ascii.equalsSign {
                    hasEquals = true
                    equalsIndex = i
                    break
                }
            }

            if hasEquals, let eqIdx = equalsIndex {
                // Parse as tag
                let keyBytes = actualContent[..<eqIdx]
                let valueBytes = actualContent[actualContent.index(after: eqIdx)...]

                guard !keyBytes.isEmpty else {
                    throw Error.invalidKey("")
                }
                guard !valueBytes.isEmpty else {
                    throw Error.invalidValue("")
                }

                let key = String(decoding: keyBytes, as: UTF8.self)

                // Validate key
                do {
                    try RFC_9557.Validation.validateSuffixKey(key)
                } catch {
                    throw Error.invalidKey(key)
                }

                // Check for experimental keys
                if RFC_9557.Validation.isExperimentalKey(key) {
                    if critical {
                        throw Error.criticalExperimentalTag(key)
                    }
                    throw Error.experimentalTagInInterchange(key)
                }

                // Parse values (split on hyphen at byte level)
                let vBytes = Array(valueBytes)
                var values: [String] = []
                var vStart = 0
                for vi in 0..<vBytes.count {
                    if vBytes[vi] == 0x2D {  // '-'
                        values.append(String(decoding: vBytes[vStart..<vi], as: UTF8.self))
                        vStart = vi &+ 1
                    }
                }
                values.append(String(decoding: vBytes[vStart..<vBytes.count], as: UTF8.self))

                for value in values {
                    do {
                        try RFC_9557.Validation.validateSuffixValue(value)
                    } catch {
                        throw Error.invalidValue(value)
                    }
                }

                // Handle u-ca specially
                if key == "u-ca" {
                    if calendar == nil {
                        calendar = values.first
                    }
                    // Ignore duplicate u-ca per spec
                } else {
                    // Check for unknown critical tags
                    if critical && !RFC_9557.Validation.isRegisteredKey(key) {
                        throw Error.criticalTagNotSupported(key)
                    }

                    // Only add first occurrence
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
                // Parse as time zone
                guard timeZone == nil else {
                    throw Error.multipleTimeZones
                }

                let tzString = String(decoding: actualContent, as: UTF8.self)

                // Check if offset or IANA
                let firstChar = actualContent[actualContent.startIndex]
                if firstChar == UInt8.ascii.plus || firstChar == UInt8.ascii.hyphen {
                    timeZone = .offset(tzString, critical: critical)
                } else {
                    do {
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

extension RFC_9557.Suffix: Binary.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_9557.Suffix: CustomStringConvertible {}

// MARK: - Convenience

extension RFC_9557.Suffix {
    /// Whether any component is marked as critical
    public var hasCriticalComponents: Bool {
        if timeZone?.isCritical == true {
            return true
        }
        return tags.contains { $0.critical }
    }
}
