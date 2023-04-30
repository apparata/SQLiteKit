import Foundation

public typealias SQLQueryString = String

public struct SQLQuery {
    
    var string: SQLQueryString
    
    public init(_ string: String) {
        self.string = string
    }
}

extension SQLQuery {
    internal static func makeQuery(@SQLQueryStringBuilder _ string: () -> SQLQuery) -> SQLQuery {
        return string()
    }
}

extension SQLQuery: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.string = value
    }
}
