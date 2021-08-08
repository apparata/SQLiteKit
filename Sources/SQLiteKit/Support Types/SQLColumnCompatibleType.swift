
import Foundation

public protocol SQLColumnCompatibleType {
    static var queryStringType: String { get }
    var queryStringValue: String { get }
}

extension String: SQLColumnCompatibleType {
    public static var queryStringType: String {
        return "TEXT"
    }
    public var queryStringValue: String {
        return "\"\(self)\""
    }
}

extension Int: SQLColumnCompatibleType {
    public static var queryStringType: String {
        return "INTEGER"
    }
    public var queryStringValue: String {
        return String(self)
    }
}

extension Double: SQLColumnCompatibleType {
    public static var queryStringType: String {
        return "REAL"
    }
    public var queryStringValue: String {
        return String(self)
    }
}

extension Data: SQLColumnCompatibleType {
    public static var queryStringType: String {
        return "BLOB"
    }
    public var queryStringValue: String {
        return "X'\(map { String(format: "%02hhx", $0) }.joined())'"
    }
}
