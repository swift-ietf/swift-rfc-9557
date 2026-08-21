extension RFC_9557 {

    public enum TimeZone: Sendable, Codable, Hashable {

        case iana(String, critical: Bool)

        case offset(String, critical: Bool)
    }
}

extension RFC_9557.TimeZone {

    public var isCritical: Bool {
        switch self {
        case .iana(_, let critical), .offset(_, let critical):
            return critical
        }
    }

    public var identifier: String {
        switch self {
        case .iana(let id, _), .offset(let id, _):
            return id
        }
    }
}

extension RFC_9557.TimeZone: CustomStringConvertible {
    public var description: String {
        let prefix = isCritical ? "!" : ""
        return "\(prefix)\(identifier)"
    }
}
