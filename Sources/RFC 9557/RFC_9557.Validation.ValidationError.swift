// MARK: - Validation Error

extension RFC_9557.Validation {
    /// Internal validation errors
    public enum ValidationError: Swift.Error, Sendable {
        case invalidSuffixKey
        case invalidSuffixValue
        case invalidTimeZoneName
    }
}
