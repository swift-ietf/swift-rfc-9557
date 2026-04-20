// EdgeCases Tests.swift
// swift-rfc-9557
//
// Tests for RFC 9557 edge cases

import Testing

@testable import RFC_9557

@Suite("RFC_9557.Timestamp - Edge Cases: Time Zones")
struct EdgeCasesTimeZoneTests {
    @Test
    func `IANA time zone case sensitivity`() throws {
        // Time zone names are case-sensitive per spec
        let ts1 = try RFC_9557.Timestamp("2022-07-08T00:14:07Z[Europe/Paris]")
        let ts2 = try RFC_9557.Timestamp("2022-07-08T00:14:07Z[europe/paris]")

        #expect(ts1.suffix?.timeZone?.identifier == "Europe/Paris")
        #expect(ts2.suffix?.timeZone?.identifier == "europe/paris")
        #expect(ts1.suffix?.timeZone != ts2.suffix?.timeZone)
    }

    @Test
    func `Offset time zones`() throws {
        let inputs = [
            ("2022-07-08T00:14:07+08:45[+08:45]", "+08:45"),
            ("2022-07-08T00:14:07-05:00[-05:00]", "-05:00"),
            ("2022-07-08T00:14:07+00:00[+00:00]", "+00:00"),
        ]

        for (input, expectedOffset) in inputs {
            let ts = try RFC_9557.Timestamp(input)
            if case .offset(let offset, _) = ts.suffix?.timeZone {
                #expect(offset == expectedOffset)
            } else {
                Issue.record("Expected offset time zone")
            }
        }
    }

    @Test
    func `Critical time zones`() throws {
        let ts = try RFC_9557.Timestamp("2022-07-08T00:14:07Z[!Europe/London]")
        #expect(ts.suffix?.timeZone?.isCritical == true)
    }

    @Test
    func `Complex IANA time zone names`() throws {
        let names = [
            "America/Argentina/Buenos_Aires",
            "America/Indiana/Indianapolis",
            "America/North_Dakota/New_Salem",
            "Etc/GMT+5",
            "Etc/GMT-8",
        ]

        for name in names {
            let input = "2022-07-08T00:14:07Z[\(name)]"
            let ts = try RFC_9557.Timestamp(input)
            #expect(ts.suffix?.timeZone?.identifier == name)
        }
    }
}

@Suite("RFC_9557.Timestamp - Edge Cases: Calendar Systems")
struct EdgeCasesCalendarTests {
    @Test
    func `Common calendar systems`() throws {
        let calendars = [
            "hebrew", "islamic", "buddhist", "chinese", "japanese", "gregory", "iso8601",
        ]

        for calendar in calendars {
            let input = "2022-07-08T00:14:07Z[u-ca=\(calendar)]"
            let ts = try RFC_9557.Timestamp(input)
            #expect(ts.suffix?.calendar == calendar)
        }
    }

    @Test
    func `Calendar value case sensitivity`() throws {
        // Values are case-sensitive per spec
        let ts1 = try RFC_9557.Timestamp("2022-07-08T00:14:07Z[u-ca=Hebrew]")
        let ts2 = try RFC_9557.Timestamp("2022-07-08T00:14:07Z[u-ca=hebrew]")

        #expect(ts1.suffix?.calendar == "Hebrew")
        #expect(ts2.suffix?.calendar == "hebrew")
        #expect(ts1.suffix?.calendar != ts2.suffix?.calendar)
    }
}

@Suite("RFC_9557.Timestamp - Edge Cases: Complex Suffixes")
struct EdgeCasesComplexSuffixTests {
    @Test
    func `Time zone + calendar`() throws {
        let input = "1996-12-19T16:39:57-08:00[America/Los_Angeles][u-ca=hebrew]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.suffix?.timeZone?.identifier == "America/Los_Angeles")
        #expect(ts.suffix?.calendar == "hebrew")
    }

    @Test
    func `Time zone + calendar + custom tags`() throws {
        let input = "2022-07-08T00:14:07Z[Europe/Paris][u-ca=gregory][foo=bar][baz=qux]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.suffix?.timeZone?.identifier == "Europe/Paris")
        #expect(ts.suffix?.calendar == "gregory")
        #expect(ts.suffix?.tags.count == 2)
    }

    @Test
    func `Multi-value suffix tags`() throws {
        let input = "2022-07-08T00:14:07Z[foo=bar-baz-qux]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.suffix?.tags.count == 1)
        #expect(ts.suffix?.tags.first?.values == ["bar", "baz", "qux"])
    }

    @Test
    func `Critical and elective tags mixed`() throws {
        let input = "2022-07-08T00:14:07Z[!u-ca=hebrew][foo=bar]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.suffix?.calendar == "hebrew")
        #expect(ts.suffix?.tags.count == 1)
        #expect(ts.suffix?.tags.first?.critical == false)
    }

    @Test
    func `Maximum complexity suffix`() throws {
        let input =
            "1996-12-19T16:39:57-08:00[!America/Los_Angeles][!u-ca=hebrew][foo=bar-baz][qux=test]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.suffix?.timeZone?.isCritical == true)
        #expect(ts.suffix?.calendar == "hebrew")
        #expect(ts.suffix?.tags.count == 2)
        #expect(ts.suffix?.hasCriticalComponents == true)
    }
}

@Suite("RFC_9557.Timestamp - Edge Cases: RFC 3339 Compatibility")
struct EdgeCasesRFC3339CompatibilityTests {
    @Test
    func `Plain RFC 3339 timestamps (backward compatible)`() throws {
        let inputs = [
            "1996-12-19T16:39:57-08:00",
            "2022-07-08T00:14:07Z",
            "2022-07-08T00:14:07+00:00",
            "1985-04-12T23:20:50.52Z",
        ]

        for input in inputs {
            let ts = try RFC_9557.Timestamp(input)
            #expect(ts.suffix == nil)
        }
    }

    @Test
    func `Fractional seconds with suffix`() throws {
        let input = "1985-04-12T23:20:50.52Z[America/New_York]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.base.time.second.value == 50)
        #expect(ts.suffix?.timeZone?.identifier == "America/New_York")
    }

    @Test
    func `Leap second with suffix`() throws {
        let input = "1990-12-31T23:59:60Z[UTC]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.base.time.second.value == 60)
        #expect(ts.suffix?.timeZone?.identifier == "UTC")
    }

    @Test
    func `Z offset with time zone (no inconsistency)`() throws {
        // Per spec: Z indicates UTC time known, local offset unknown
        // Adding a time zone is not an inconsistency
        let input = "2022-07-08T00:14:07Z[Europe/Paris]"
        let ts = try RFC_9557.Timestamp(input)

        #expect(ts.base.offset == .utc)
        #expect(ts.suffix?.timeZone?.identifier == "Europe/Paris")
    }
}

@Suite("RFC_9557.Timestamp - Edge Cases: Minimal Inputs")
struct EdgeCasesMinimalInputTests {
    @Test
    func `Single character time zone`() throws {
        let input = "2022-07-08T00:14:07Z[Z]"
        let ts = try RFC_9557.Timestamp(input)
        #expect(ts.suffix?.timeZone?.identifier == "Z")
    }

    @Test
    func `Single character key and value`() throws {
        let input = "2022-07-08T00:14:07Z[a=b]"
        let ts = try RFC_9557.Timestamp(input)
        #expect(ts.suffix?.tags.first?.key == "a")
        #expect(ts.suffix?.tags.first?.values == ["b"])
    }
}
