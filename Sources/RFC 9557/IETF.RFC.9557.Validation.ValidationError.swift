extension IETF.RFC.`9557`.Validation {

    public enum ValidationError: Swift::Error, Sendable {
        case invalidSuffixKey
        case invalidSuffixValue
        case invalidTimeZoneName
        case invalidTimeZoneOffset
    }
}
