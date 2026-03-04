//
//  RFC_9557.Suffix.Parse.swift
//  swift-rfc-9557
//
//  RFC 9557 suffix: *("[" [critical-flag] content "]")
//

public import Parser_Primitives

extension RFC_9557.Suffix {
    /// Parses RFC 9557 suffix annotations.
    ///
    /// Suffix annotations are bracket-delimited groups appended to
    /// RFC 3339 timestamps.
    ///
    /// Each group is `[` optional `!` critical-flag, then either:
    /// - A timezone identifier (no `=` sign)
    /// - A key `=` value tag (values separated by `-`)
    ///
    /// Returns an array of `Annotation` values, each containing the
    /// raw content bytes, whether a critical flag was present, and
    /// whether the content is a key-value tag or a timezone.
    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

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

    public typealias Output = [Annotation]

    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedOpenBracket
        case unterminatedBracket
        case emptyBracket
    }
}

extension RFC_9557.Suffix.Parse: Parser.`Protocol` {
    public typealias ParseOutput = Output
    public typealias Failure = RFC_9557.Suffix.Parse<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        var annotations: [Annotation] = []

        while input.startIndex < input.endIndex {
            // Expect '[' (0x5B)
            guard input[input.startIndex] == 0x5B else {
                break
            }
            input = input[input.index(after: input.startIndex)...]

            guard input.startIndex < input.endIndex else {
                throw .unterminatedBracket
            }

            // Check for critical flag '!' (0x21)
            let critical: Bool
            if input[input.startIndex] == 0x21 {
                critical = true
                input = input[input.index(after: input.startIndex)...]
            } else {
                critical = false
            }

            // Consume content until ']' (0x5D)
            let contentStart = input.startIndex
            while input.startIndex < input.endIndex
                && input[input.startIndex] != 0x5D
            {
                input = input[input.index(after: input.startIndex)...]
            }

            guard input.startIndex < input.endIndex else {
                throw .unterminatedBracket
            }

            let content = input[contentStart..<input.startIndex]
            guard contentStart < input.startIndex else {
                throw .emptyBracket
            }

            annotations.append(Annotation(critical: critical, content: content))

            // Skip ']'
            input = input[input.index(after: input.startIndex)...]
        }

        return annotations
    }
}
