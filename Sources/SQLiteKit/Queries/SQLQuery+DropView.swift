//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation

extension SQLQuery {
    
    public static func dropView(_ view: SQLView, options: DropViewOptions = []) -> SQLQuery {
        makeQuery {
            "DROP VIEW"
            if options.contains(.ifExists) { "IF EXISTS" }
            if let schema = view.schemaName {
                "\(schema).\(view.name)"
            } else {
                view.name
            }
            if !options.contains(.excludeSemicolon) {
                ";"
            }
        }
    }
    
    public struct DropViewOptions: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let ifExists = Self(rawValue: 1 << 0)
        public static let excludeSemicolon = Self(rawValue: 1 << 3)

        public static let all: Self = [.ifExists, .excludeSemicolon]
    }
}
