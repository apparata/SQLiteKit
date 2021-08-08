//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation

extension SQLQuery {
    
    public static func dropTable(_ table: SQLTable, options: DropTableOptions = []) -> SQLQuery {
        makeQuery {
            "DROP TABLE"
            if options.contains(.ifExists) { "IF EXISTS" }
            if let schema = table.schemaName {
                "\(schema).\(table.name)"
            } else {
                table.name
            }
            if !options.contains(.excludeSemicolon) {
                ";"
            }
        }
    }
    
    public struct DropTableOptions: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let ifExists = Self(rawValue: 1 << 0)
        public static let excludeSemicolon = Self(rawValue: 1 << 3)

        public static let all: Self = [.ifExists, .excludeSemicolon]
    }
}
