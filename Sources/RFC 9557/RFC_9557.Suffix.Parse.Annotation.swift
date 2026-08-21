extension RFC_9557.Suffix.Parse {
    public struct Annotation: Sendable {

        public let critical: Bool

        public let content: Input

        @inlinable
        public init(critical: Bool, content: Input) {
            self.critical = critical
            self.content = content
        }
    }
}
