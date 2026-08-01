extension RFC_9557.Suffix.Parse {
    public struct Annotation: Sendable {
        /// Whether the `!` critical flag was present.
        public let critical: Bool
        /// The content between brackets (excluding critical flag).
        public let content: Input

        @inlinable
        public init(critical: Bool, content: Input) {
            self.critical = critical
            self.content = content
        }
    }
}
