// Validation Tests.swift
// swift-rfc-9557
//
// Tests for RFC_9557.Validation

import Testing

@testable import RFC_9557

@Suite("RFC_9557.Validation - Suffix Key Format")
struct ValidationSuffixKeyTests {
    @Test
    func `Valid lowercase keys`() throws {
        try RFC_9557.Validation.validateSuffixKey("u-ca")
        try RFC_9557.Validation.validateSuffixKey("foo")
        try RFC_9557.Validation.validateSuffixKey("foo-bar")
        try RFC_9557.Validation.validateSuffixKey("key123")
        try RFC_9557.Validation.validateSuffixKey("a")
    }

    @Test
    func `Valid experimental keys (underscore prefix)`() throws {
        try RFC_9557.Validation.validateSuffixKey("_foo")
        try RFC_9557.Validation.validateSuffixKey("_bar-baz")
        try RFC_9557.Validation.validateSuffixKey("_test123")
        try RFC_9557.Validation.validateSuffixKey("_")
    }

    @Test
    func `Invalid: uppercase letters`() {
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateSuffixKey("U-CA")
        }
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateSuffixKey("Foo")
        }
    }

    @Test
    func `Invalid: starts with digit`() {
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateSuffixKey("1foo")
        }
    }

    @Test
    func `Invalid: starts with hyphen`() {
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateSuffixKey("-foo")
        }
    }

    @Test
    func `Invalid: contains invalid characters`() {
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateSuffixKey("foo@bar")
        }
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateSuffixKey("foo.bar")
        }
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateSuffixKey("foo bar")
        }
    }

    @Test
    func `Invalid: empty key`() {
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateSuffixKey("")
        }
    }

    @Test
    func `Experimental key detection`() {
        #expect(RFC_9557.Validation.isExperimentalKey("_foo"))
        #expect(RFC_9557.Validation.isExperimentalKey("_"))
        #expect(!RFC_9557.Validation.isExperimentalKey("foo"))
        #expect(!RFC_9557.Validation.isExperimentalKey("u-ca"))
    }
}

@Suite("RFC_9557.Validation - Suffix Value Format")
struct ValidationSuffixValueTests {
    @Test
    func `Valid alphanumeric values`() throws {
        try RFC_9557.Validation.validateSuffixValue("hebrew")
        try RFC_9557.Validation.validateSuffixValue("iso8601")
        try RFC_9557.Validation.validateSuffixValue("ABC123")
        try RFC_9557.Validation.validateSuffixValue("a")
        try RFC_9557.Validation.validateSuffixValue("1")
    }

    @Test
    func `Invalid: contains hyphens`() {
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateSuffixValue("foo-bar")
        }
    }

    @Test
    func `Invalid: contains special characters`() {
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateSuffixValue("foo@bar")
        }
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateSuffixValue("foo.bar")
        }
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateSuffixValue("foo_bar")
        }
    }

    @Test
    func `Invalid: empty value`() {
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateSuffixValue("")
        }
    }
}

@Suite("RFC_9557.Validation - Time Zone Name Format")
struct ValidationTimeZoneNameTests {
    @Test
    func `Valid IANA time zone names`() throws {
        try RFC_9557.Validation.validateTimeZoneName("America/Los_Angeles")
        try RFC_9557.Validation.validateTimeZoneName("Europe/Paris")
        try RFC_9557.Validation.validateTimeZoneName("Asia/Tokyo")
        try RFC_9557.Validation.validateTimeZoneName("UTC")
        try RFC_9557.Validation.validateTimeZoneName("Etc/GMT+5")
    }

    @Test
    func `Valid: names with dots and underscores`() throws {
        try RFC_9557.Validation.validateTimeZoneName("America/Indiana/Knox_IN.Starke")
        try RFC_9557.Validation.validateTimeZoneName("America/Argentina/ComodRivadavia")
    }

    @Test
    func `Invalid: dot-only parts`() {
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateTimeZoneName(".")
        }
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateTimeZoneName("..")
        }
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateTimeZoneName("America/.")
        }
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateTimeZoneName("../Europe")
        }
    }

    @Test
    func `Invalid: special characters`() {
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateTimeZoneName("America/Los@Angeles")
        }
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateTimeZoneName("Europe\\Paris")
        }
    }

    @Test
    func `Invalid: empty name`() {
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateTimeZoneName("")
        }
    }
}

@Suite("RFC_9557.Validation - Registered Keys")
struct ValidationRegisteredKeysTests {
    @Test
    func `u-ca is registered`() {
        #expect(RFC_9557.Validation.isRegisteredKey("u-ca"))
    }

    @Test
    func `Unknown keys are not registered`() {
        #expect(!RFC_9557.Validation.isRegisteredKey("foo"))
        #expect(!RFC_9557.Validation.isRegisteredKey("bar"))
        #expect(!RFC_9557.Validation.isRegisteredKey("_experimental"))
    }
}
