extension RFC_9557.Suffix {

    public struct Calendar: Sendable, Codable, Hashable {

        public let identifier: String

        public let isCritical: Bool

        init(__unchecked: Void, identifier: String, isCritical: Bool) {
            self.identifier = identifier
            self.isCritical = isCritical
        }

        public init(_ identifier: String) throws(Error) {
            do throws(RFC_9557.Validation.ValidationError) {
                try RFC_9557.Validation.validateSuffixValue(identifier)
            } catch {
                throw Error.invalidValue(identifier)
            }
            self.init(__unchecked: (), identifier: identifier, isCritical: false)
        }

        public static func critical(_ identifier: String) throws(Error) -> Self {
            let elective = try Self(identifier)
            return Self(__unchecked: (), identifier: elective.identifier, isCritical: true)
        }
    }
}

extension RFC_9557.Suffix.Calendar: CustomStringConvertible {
    public var description: String {
        let prefix = isCritical ? "!" : ""
        return "\(prefix)\(identifier)"
    }
}
