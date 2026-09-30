import Testing

@testable import RFC_9557

@Suite
struct `Time zone name parts` {
    @Test(arguments: ["America//New_York", "/UTC", "UTC/", "/"])
    func `an empty part is refused`(_ name: String) {
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateTimeZoneName(name)
        }
    }

    @Test(arguments: ["1Europe", "Etc/-5", "Etc/+5", "America/9abc"])
    func `a part must start with a letter, a dot or an underscore`(_ name: String) {
        #expect(throws: RFC_9557.Validation.ValidationError.self) {
            try RFC_9557.Validation.validateTimeZoneName(name)
        }
    }

    @Test(arguments: ["_private", ".hidden/Zone", "Etc/GMT-14", "..."])
    func `a part may start with a dot or an underscore and continue with any zone character`(_ name: String) throws {
        try RFC_9557.Validation.validateTimeZoneName(name)
    }
}
