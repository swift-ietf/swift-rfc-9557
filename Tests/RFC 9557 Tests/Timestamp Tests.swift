// Timestamp Tests.swift
// swift-rfc-9557
//
// Tests for RFC_9557.Timestamp

import Testing

@testable import RFC_9557

@Suite("RFC_9557.Timestamp - Basic Parsing")
struct TimestampBasicTests {
    @Test
    func `Parse RFC 3339 without suffix`() throws {
        let input = "1996-12-19T16:39:57-08:00"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.base.time.year == 1996)
        #expect(ts.base.offset == .offset(seconds: -28800))
        #expect(ts.suffix == nil)
    }

    @Test
    func `Parse with IANA time zone`() throws {
        let input = "1996-12-19T16:39:57-08:00[America/Los_Angeles]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.base.time.year == 1996)
        #expect(ts.suffix?.timeZone == .iana("America/Los_Angeles", critical: false))
    }

    @Test
    func `Parse with critical IANA time zone`() throws {
        let input = "1996-12-19T16:39:57-08:00[!America/Los_Angeles]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.suffix?.timeZone == .iana("America/Los_Angeles", critical: true))
        #expect(ts.suffix?.timeZone?.isCritical == true)
    }

    @Test
    func `Parse with offset time zone`() throws {
        let input = "2024-01-01T00:00:00+00:00[+08:45]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.suffix?.timeZone == .offset("+08:45", critical: false))
    }

    @Test
    func `Parse with calendar system`() throws {
        let input = "2024-01-01T00:00:00Z[Asia/Jerusalem][u-ca=hebrew]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.suffix?.timeZone == .iana("Asia/Jerusalem", critical: false))
        #expect(ts.suffix?.calendar == "hebrew")
    }

    @Test
    func `Parse with multiple suffix tags`() throws {
        let input = "2024-01-01T00:00:00Z[Europe/Paris][u-ca=gregory]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.suffix?.timeZone == .iana("Europe/Paris", critical: false))
        #expect(ts.suffix?.calendar == "gregory")
    }
}

@Suite("RFC_9557.Timestamp - Examples from RFC")
struct TimestampRFCExamplesTests {
    @Test
    func `Example 1: Basic timestamp with time zone`() throws {
        let input = "1996-12-19T16:39:57-08:00[America/Los_Angeles]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.base.time.year == 1996)
        #expect(ts.base.time.month == 12)
        #expect(ts.base.time.day == 19)
        #expect(ts.suffix?.timeZone?.identifier == "America/Los_Angeles")
    }

    @Test
    func `Example 2: With calendar system`() throws {
        let input = "2022-07-08T00:14:07Z[Europe/London][u-ca=iso8601]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.base.time.year == 2022)
        #expect(ts.suffix?.timeZone?.identifier == "Europe/London")
        #expect(ts.suffix?.calendar == "iso8601")
    }
}

@Suite("RFC_9557.Timestamp - Serialization")
struct TimestampSerializationTests {
    @Test
    func `Serialize without suffix`() throws {
        let time = try Time(year: 1996, month: 12, day: 19, hour: 16, minute: 39, second: 57)
        let base = RFC_3339.DateTime(time: time, offset: .offset(seconds: -28800))
        let ts = RFC_9557.Timestamp(base: base)

        let formatted = String(ts)
        #expect(formatted == "1996-12-19T16:39:57-08:00")
    }

    @Test
    func `Serialize with IANA time zone`() throws {
        let time = try Time(year: 1996, month: 12, day: 19, hour: 16, minute: 39, second: 57)
        let base = RFC_3339.DateTime(time: time, offset: .offset(seconds: -28800))
        let suffix = RFC_9557.Suffix(timeZone: .iana("America/Los_Angeles", critical: false))
        let ts = RFC_9557.Timestamp(base: base, suffix: suffix)

        let formatted = String(ts)
        #expect(formatted == "1996-12-19T16:39:57-08:00[America/Los_Angeles]")
    }

    @Test
    func `Serialize with critical time zone`() throws {
        let time = try Time(year: 1996, month: 12, day: 19, hour: 16, minute: 39, second: 57)
        let base = RFC_3339.DateTime(time: time, offset: .offset(seconds: -28800))
        let suffix = RFC_9557.Suffix(timeZone: .iana("America/Los_Angeles", critical: true))
        let ts = RFC_9557.Timestamp(base: base, suffix: suffix)

        let formatted = String(ts)
        #expect(formatted == "1996-12-19T16:39:57-08:00[!America/Los_Angeles]")
    }

    @Test
    func `Serialize with calendar system`() throws {
        let time = try Time(year: 2024, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        let base = RFC_3339.DateTime(time: time, offset: .utc)
        let suffix = RFC_9557.Suffix(
            timeZone: .iana("Asia/Jerusalem", critical: false),
            calendar: "hebrew"
        )
        let ts = RFC_9557.Timestamp(base: base, suffix: suffix)

        let formatted = String(ts)
        #expect(formatted == "2024-01-01T00:00:00Z[Asia/Jerusalem][u-ca=hebrew]")
    }

    @Test
    func `Round-trip: parse then serialize`() throws {
        let original = "1996-12-19T16:39:57-08:00[America/Los_Angeles]"
        let ts = try RFC_9557.Timestamp(original)
        let serialized = String(ts)

        #expect(serialized == original)
    }

    @Test
    func `Round-trip with calendar`() throws {
        let original = "2024-01-01T00:00:00Z[Europe/Paris][u-ca=gregory]"
        let ts = try RFC_9557.Timestamp(original)
        let serialized = String(ts)

        #expect(serialized == original)
    }
}
