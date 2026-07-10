//
//  RFC_9557.__SuffixParseError.swift
//  swift-rfc-9557
//
//  Module-scope, non-generic error for the RFC 9557 suffix parser.
//
//  Hoisted out of the generic `RFC_9557.Suffix.Parse<Input>` namespace so the
//  `@error` SIL result carries no phantom `Input` type parameter — the structural
//  fix for the `FunctionSignatureOpts` release-build ICE
//  (`SILArgument.cpp:40 !type.hasTypeParameter()`; Research §A13 / swiftlang/swift#89617).
//  Surfaced through the public path `RFC_9557.Suffix.Parse.Error` (a typealias).
//

/// Errors that can occur when parsing an RFC 9557 suffix.
public enum __SuffixParseError: Swift.Error, Sendable, Equatable {
    /// A suffix group did not begin with the required `[` open bracket.
    case expectedOpenBracket
    /// A `[` bracket group was never closed by a matching `]`.
    case unterminatedBracket
    /// A bracket group contained no content between `[` and `]`.
    case emptyBracket
}
