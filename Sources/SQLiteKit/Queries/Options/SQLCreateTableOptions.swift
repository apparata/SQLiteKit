import Foundation

public struct SQLCreateTableOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let ifNotExists = Self(rawValue: 1 << 0)
    public static let temporary = Self(rawValue: 1 << 1)
    public static let withoutRowID = Self(rawValue: 1 << 2)
    public static let excludeSemicolon = Self(rawValue: 1 << 3)

    public static let all: Self = [.ifNotExists, .temporary, .withoutRowID, .excludeSemicolon]
}
