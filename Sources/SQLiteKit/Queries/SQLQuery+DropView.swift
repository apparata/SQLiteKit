//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation

extension SQLQuery {
    
    public static func dropView(_ view: SQLView, options: SQLDropOptions = []) -> SQLQuery {
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
}
