import Testing

@testable import RFC_9557

enum `RFC_9557.Suffix Tests` {}

extension `RFC_9557.Suffix Tests` {
    @Suite
    struct Test {
        @Test
        func `Reject critical unknown tags`() {
            let input = "2022-07-08T00:14:07Z[!knort=blargel]"
            #expect(throws: RFC_9557.Timestamp.Error.self) {
                try RFC_9557.Timestamp(input)
            }
        }

        @Test
        func `Accept elective unknown tags`() throws {
            let input = "2022-07-08T00:14:07Z[knort=blargel]"
            let ts = try RFC_9557.Timestamp(input)
            #expect(ts.suffix?.tags.count == 1)
            #expect(ts.suffix?.tags.first?.key == "knort")
        }

        @Test
        func `Reject critical experimental tags`() {
            let input = "[!_foo=bar]"
            #expect(throws: RFC_9557.Suffix.Error.self) {
                try RFC_9557.Suffix(ascii: [Byte](utf8: input))
            }
        }

        @Test
        func `Accept critical registered tags (u-ca)`() throws {
            let input = "2022-07-08T00:14:07Z[!u-ca=hebrew]"
            let ts = try RFC_9557.Timestamp(input)
            #expect(ts.suffix?.calendar?.identifier == "hebrew")
        }
    }
}

extension `RFC_9557.Suffix Tests`.Test {
    @Suite
    struct `Error Experimental Tag` {
        @Test
        func `Reject experimental tags in normal parse`() {
            let input = "[_foo=bar]"
            #expect(throws: RFC_9557.Suffix.Error.self) {
                try RFC_9557.Suffix(ascii: [Byte](utf8: input))
            }
        }
    }
}

extension `RFC_9557.Suffix Tests`.Test {
    @Suite
    struct `Error Invalid Format` {
        @Test
        func `Reject malformed brackets: unclosed`() {
            let input = "[Europe/Paris"
            #expect(throws: RFC_9557.Suffix.Error.self) {
                try RFC_9557.Suffix(ascii: [Byte](utf8: input))
            }
        }

        @Test
        func `Reject empty tags`() {
            #expect(throws: RFC_9557.Suffix.Error.self) {
                try RFC_9557.Suffix(ascii: [Byte](utf8: "[]"))
            }
            #expect(throws: RFC_9557.Suffix.Error.self) {
                try RFC_9557.Suffix(ascii: [Byte](utf8: "[!]"))
            }
        }

        @Test
        func `Reject multiple time zones`() {
            let input = "[Europe/Paris][America/New_York]"
            #expect(throws: RFC_9557.Suffix.Error.self) {
                try RFC_9557.Suffix(ascii: [Byte](utf8: input))
            }
        }

        @Test
        func `Reject invalid suffix keys`() {

            #expect(throws: RFC_9557.Suffix.Error.self) {
                try RFC_9557.Suffix(ascii: [Byte](utf8: "[U-CA=hebrew]"))
            }

            #expect(throws: RFC_9557.Suffix.Error.self) {
                try RFC_9557.Suffix(ascii: [Byte](utf8: "[1foo=bar]"))
            }
        }

        @Test
        func `Reject invalid suffix values`() {

            #expect(throws: RFC_9557.Suffix.Error.self) {
                try RFC_9557.Suffix(ascii: [Byte](utf8: "[u-ca=foo@bar]"))
            }
        }

        @Test
        func `Reject invalid time zone names`() {

            #expect(throws: RFC_9557.Suffix.Error.self) {
                try RFC_9557.Suffix(ascii: [Byte](utf8: "[.]"))
            }

            #expect(throws: RFC_9557.Suffix.Error.self) {
                try RFC_9557.Suffix(ascii: [Byte](utf8: "[..]"))
            }
        }
    }
}

extension `RFC_9557.Suffix Tests`.Test {
    @Suite
    struct `Error Duplicate Key` {
        @Test
        func `Duplicate u-ca tags: use first occurrence`() throws {
            let input = "2022-07-08T00:14:07Z[u-ca=chinese][u-ca=japanese]"
            let ts = try RFC_9557.Timestamp(input)
            #expect(ts.suffix?.calendar?.identifier == "chinese")
        }

        @Test
        func `Duplicate elective tags: use first occurrence`() throws {
            let input = "2022-07-08T00:14:07Z[foo=bar][foo=baz]"
            let ts = try RFC_9557.Timestamp(input)
            #expect(ts.suffix?.tags.count == 1)
            #expect(ts.suffix?.tags.first?.values == ["bar"])
        }

        @Test
        func `Mixed duplicate and unique tags`() throws {
            let input = "2022-07-08T00:14:07Z[foo=a][bar=b][foo=c][baz=d]"
            let ts = try RFC_9557.Timestamp(input)
            #expect(ts.suffix?.tags.count == 3)

            let fooTag = ts.suffix?.tags.first { $0.key == "foo" }
            #expect(fooTag?.values == ["a"])

            #expect(ts.suffix?.tags.contains { $0.key == "bar" } == true)
            #expect(ts.suffix?.tags.contains { $0.key == "baz" } == true)
        }
    }
}

extension `RFC_9557.Suffix Tests`.Test {
    @Suite
    struct `Bytes Outside Brackets` {
        @Test(arguments: ["[Europe/Paris]junk", "x[UTC]", "[UTC] [u-ca=hebrew]", "[UTC]]"])
        func `bytes outside brackets are refused`(_ input: String) {
            #expect(throws: RFC_9557.Suffix.Error.malformedBrackets(input)) {
                try RFC_9557.Suffix(input)
            }
        }

        @Test
        func `a timestamp with junk after its suffix is refused`() {
            #expect(throws: RFC_9557.Timestamp.Error.self) {
                try RFC_9557.Timestamp("2022-07-08T00:14:07Z[Europe/Paris]junk")
            }
        }
    }
}

extension `RFC_9557.Suffix Tests`.Test {
    @Suite
    struct `Offset Time Zone` {
        @Test(arguments: ["+banana", "+8:45", "+08:60", "+24:00", "-0800", "+08:45:00", "+"])
        func `an offset that is not an RFC 3339 offset is refused`(_ offset: String) {
            #expect(throws: RFC_9557.Suffix.Error.invalidTimeZoneOffset(offset)) {
                try RFC_9557.Suffix("[\(offset)]")
            }
            #expect(throws: RFC_9557.Suffix.Error.invalidTimeZoneOffset(offset)) {
                try RFC_9557.Suffix(timeZone: .offset(offset, critical: false))
            }
        }

        @Test(arguments: ["+00:00", "-00:00", "+23:59", "-12:30"])
        func `an RFC 3339 offset is accepted`(_ offset: String) throws {
            let suffix = try RFC_9557.Suffix("[\(offset)]")
            #expect(suffix.timeZone == .offset(offset, critical: false))
        }
    }
}

extension `RFC_9557.Suffix Tests`.Test {
    @Suite
    struct `Critical Calendar` {
        @Test
        func `a critical calendar keeps its flag through a round trip`() throws {
            let input = "2022-07-08T00:14:07Z[!u-ca=hebrew]"
            let ts = try RFC_9557.Timestamp(input)
            #expect(ts.suffix?.calendar == (try RFC_9557.Suffix.Calendar.critical("hebrew")))
            #expect(ts.suffix?.hasCriticalComponents == true)
            #expect(String(ts) == input)
        }

        @Test
        func `an elective calendar is written without a flag`() throws {
            let input = "2022-07-08T00:14:07Z[u-ca=hebrew]"
            let ts = try RFC_9557.Timestamp(input)
            #expect(ts.suffix?.calendar?.isCritical == false)
            #expect(String(ts) == input)
        }
    }
}

extension `RFC_9557.Suffix Tests`.Test {
    @Suite
    struct `Built Suffix` {
        @Test(arguments: ["", "foo@bar", "islamic-civil"])
        func `an invalid calendar is refused`(_ identifier: String) {
            #expect(throws: RFC_9557.Suffix.Error.invalidValue(identifier)) {
                try RFC_9557.Suffix.Calendar(identifier)
            }
        }

        @Test
        func `an invalid time zone name is refused`() {
            #expect(throws: RFC_9557.Suffix.Error.invalidTimeZoneName("..")) {
                try RFC_9557.Suffix(timeZone: .iana("..", critical: false))
            }
        }

        @Test
        func `a repeated tag key is refused`() throws {
            let first = try RFC_9557.Suffix.Tag(key: "foo", values: ["a"], critical: false)
            let second = try RFC_9557.Suffix.Tag(key: "foo", values: ["b"], critical: false)
            #expect(throws: RFC_9557.Suffix.Error.duplicateKey("foo")) {
                try RFC_9557.Suffix(tags: [first, second])
            }
        }

        @Test
        func `a u-ca tag is refused beside the calendar`() throws {
            let tag = try RFC_9557.Suffix.Tag(key: "u-ca", values: ["hebrew"], critical: false)
            #expect(throws: RFC_9557.Suffix.Error.duplicateKey("u-ca")) {
                try RFC_9557.Suffix(tags: [tag])
            }
        }

        @Test
        func `a built suffix parses back to itself`() throws {
            let suffix = try RFC_9557.Suffix(
                timeZone: .offset("+08:45", critical: true),
                calendar: .critical("hebrew"),
                tags: [RFC_9557.Suffix.Tag(key: "foo", values: ["a", "b"], critical: false)]
            )
            #expect(try RFC_9557.Suffix(suffix.rawValue) == suffix)
        }
    }
}

extension `RFC_9557.Suffix Tests`.Test {
    @Suite
    struct `Built Tag` {
        @Test(arguments: [false, true])
        func `an experimental key is refused`(_ critical: Bool) {
            #expect(throws: RFC_9557.Suffix.Tag.Error.experimentalKey("_foo")) {
                try RFC_9557.Suffix.Tag(key: "_foo", values: ["bar"], critical: critical)
            }
        }

        @Test
        func `a critical unregistered key is refused`() {
            #expect(throws: RFC_9557.Suffix.Tag.Error.criticalTagNotSupported("knort")) {
                try RFC_9557.Suffix.Tag(key: "knort", values: ["blargel"], critical: true)
            }
        }

        @Test
        func `a critical registered key is accepted`() throws {
            let tag = try RFC_9557.Suffix.Tag(key: "u-ca", values: ["hebrew"], critical: true)
            #expect(tag.critical)
        }
    }
}
