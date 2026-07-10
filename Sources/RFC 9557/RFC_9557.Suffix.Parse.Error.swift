//
//  RFC_9557.Suffix.Parse.Error.swift
//  swift-rfc-9557
//
//  Public-path alias onto the module-scope `__SuffixParseError`.
//
//  The error was hoisted out of the generic `Parse<Input>` context (see
//  `RFC_9557.__SuffixParseError.swift`) to dodge the `FunctionSignatureOpts`
//  §A13 ICE; this typealias preserves the `RFC_9557.Suffix.Parse.Error`
//  spelling for source compatibility.
//

extension RFC_9557.Suffix.Parse {
    /// Errors that can occur when parsing an RFC 9557 suffix.
    public typealias Error = __SuffixParseError
}
