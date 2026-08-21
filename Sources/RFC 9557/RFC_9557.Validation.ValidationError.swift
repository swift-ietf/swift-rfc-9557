extension RFC_9557.Validation {

    public enum ValidationError: Swift.Error, Sendable {
        case invalidSuffixKey
        case invalidSuffixValue
        case invalidTimeZoneName
    }
}
