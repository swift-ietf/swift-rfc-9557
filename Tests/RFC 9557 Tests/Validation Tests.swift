import Testing

@testable import RFC_9557

enum `IETF.RFC.9557.Validation Tests` {}

extension `IETF.RFC.9557.Validation Tests` {
    @Suite
    struct Test {
        @Test
        func `Valid lowercase keys`() throws {
            try IETF.RFC.`9557`.Validation.validateSuffixKey("u-ca")
            try IETF.RFC.`9557`.Validation.validateSuffixKey("foo")
            try IETF.RFC.`9557`.Validation.validateSuffixKey("foo-bar")
            try IETF.RFC.`9557`.Validation.validateSuffixKey("key123")
            try IETF.RFC.`9557`.Validation.validateSuffixKey("a")
        }

        @Test
        func `Valid experimental keys (underscore prefix)`() throws {
            try IETF.RFC.`9557`.Validation.validateSuffixKey("_foo")
            try IETF.RFC.`9557`.Validation.validateSuffixKey("_bar-baz")
            try IETF.RFC.`9557`.Validation.validateSuffixKey("_test123")
            try IETF.RFC.`9557`.Validation.validateSuffixKey("_")
        }

        @Test
        func `Invalid: uppercase letters`() {
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateSuffixKey("U-CA")
            }
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateSuffixKey("Foo")
            }
        }

        @Test
        func `Invalid: starts with digit`() {
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateSuffixKey("1foo")
            }
        }

        @Test
        func `Invalid: starts with hyphen`() {
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateSuffixKey("-foo")
            }
        }

        @Test
        func `Invalid: contains invalid characters`() {
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateSuffixKey("foo@bar")
            }
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateSuffixKey("foo.bar")
            }
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateSuffixKey("foo bar")
            }
        }

        @Test
        func `Invalid: empty key`() {
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateSuffixKey("")
            }
        }

        @Test
        func `Experimental key detection`() {
            #expect(IETF.RFC.`9557`.Validation.isExperimentalKey("_foo"))
            #expect(IETF.RFC.`9557`.Validation.isExperimentalKey("_"))
            #expect(!IETF.RFC.`9557`.Validation.isExperimentalKey("foo"))
            #expect(!IETF.RFC.`9557`.Validation.isExperimentalKey("u-ca"))
        }
    }
}

extension `IETF.RFC.9557.Validation Tests`.Test {
    @Suite
    struct `Suffix Value` {
        @Test
        func `Valid alphanumeric values`() throws {
            try IETF.RFC.`9557`.Validation.validateSuffixValue("hebrew")
            try IETF.RFC.`9557`.Validation.validateSuffixValue("iso8601")
            try IETF.RFC.`9557`.Validation.validateSuffixValue("ABC123")
            try IETF.RFC.`9557`.Validation.validateSuffixValue("a")
            try IETF.RFC.`9557`.Validation.validateSuffixValue("1")
        }

        @Test
        func `Invalid: contains hyphens`() {
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateSuffixValue("foo-bar")
            }
        }

        @Test
        func `Invalid: contains special characters`() {
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateSuffixValue("foo@bar")
            }
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateSuffixValue("foo.bar")
            }
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateSuffixValue("foo_bar")
            }
        }

        @Test
        func `Invalid: empty value`() {
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateSuffixValue("")
            }
        }
    }
}

extension `IETF.RFC.9557.Validation Tests`.Test {
    @Suite
    struct `Time Zone Name` {
        @Test
        func `Valid IANA time zone names`() throws {
            try IETF.RFC.`9557`.Validation.validateTimeZoneName("America/Los_Angeles")
            try IETF.RFC.`9557`.Validation.validateTimeZoneName("Europe/Paris")
            try IETF.RFC.`9557`.Validation.validateTimeZoneName("Asia/Tokyo")
            try IETF.RFC.`9557`.Validation.validateTimeZoneName("UTC")
            try IETF.RFC.`9557`.Validation.validateTimeZoneName("Etc/GMT+5")
        }

        @Test
        func `Valid: names with dots and underscores`() throws {
            try IETF.RFC.`9557`.Validation.validateTimeZoneName("America/Indiana/Knox_IN.Starke")
            try IETF.RFC.`9557`.Validation.validateTimeZoneName("America/Argentina/ComodRivadavia")
        }

        @Test
        func `Invalid: dot-only parts`() {
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateTimeZoneName(".")
            }
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateTimeZoneName("..")
            }
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateTimeZoneName("America/.")
            }
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateTimeZoneName("../Europe")
            }
        }

        @Test
        func `Invalid: special characters`() {
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateTimeZoneName("America/Los@Angeles")
            }
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateTimeZoneName("Europe\\Paris")
            }
        }

        @Test
        func `Invalid: empty name`() {
            #expect(throws: IETF.RFC.`9557`.Validation.ValidationError.self) {
                try IETF.RFC.`9557`.Validation.validateTimeZoneName("")
            }
        }
    }
}

extension `IETF.RFC.9557.Validation Tests`.Test {
    @Suite
    struct `Registered Keys` {
        @Test
        func `u-ca is registered`() {
            #expect(IETF.RFC.`9557`.Validation.isRegisteredKey("u-ca"))
        }

        @Test
        func `Unknown keys are not registered`() {
            #expect(!IETF.RFC.`9557`.Validation.isRegisteredKey("foo"))
            #expect(!IETF.RFC.`9557`.Validation.isRegisteredKey("bar"))
            #expect(!IETF.RFC.`9557`.Validation.isRegisteredKey("_experimental"))
        }
    }
}
