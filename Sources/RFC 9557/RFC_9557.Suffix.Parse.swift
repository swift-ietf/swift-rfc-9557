public import Parser_Primitives

extension RFC_9557.Suffix {

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_9557.Suffix.Parse {
    public typealias Output = [Annotation]
}

extension RFC_9557.Suffix.Parse: Parser.`Protocol` {
    public typealias Failure = __SuffixParseError
    public typealias Body = Never

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        var annotations: [Annotation] = []

        while input.startIndex < input.endIndex {

            guard input[input.startIndex] == 0x5B else {
                break
            }
            input = input[input.index(after: input.startIndex)...]

            guard input.startIndex < input.endIndex else {
                throw .unterminatedBracket
            }

            let critical: Bool
            if input[input.startIndex] == 0x21 {
                critical = true
                input = input[input.index(after: input.startIndex)...]
            } else {
                critical = false
            }

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

            input = input[input.index(after: input.startIndex)...]
        }

        return annotations
    }
}
