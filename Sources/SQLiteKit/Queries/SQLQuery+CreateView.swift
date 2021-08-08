//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation

extension SQLQuery {
    
    public static func createView(_ view: SQLView, options: CreateViewOptions = []) -> SQLQuery {
        
        @SQLQueryStringBuilder
        func makeColumn(_ column: SQLTableColumn) -> SQLQueryString {
            column
            column.dataType
            if column.notNullable {
                "NOT NULL"
                if let onConflict = column.notNullableOnConflict {
                    onConflict
                }
            }
            if let defaultTo = column.defaultToAsString {
                "DEFAULT \(defaultTo)"
            }
            if let collation = column.collationName {
                "COLLATE \(collation)"
            }
            if let generatedAs = column.generatedAsExpression {
                "GENERATED ALWAYS AS (\(generatedAs))"
                if column.generatedAsStored {
                    "STORED"
                }
            }
        }
        
        @SQLQueryStringBuilder
        func makeColumns(_ view: SQLView) -> [String] {
            for column in view.columns {
                makeColumn(column)
            }
        }
        
        return makeQuery {
            "CREATE"
            if options.contains(.temporary) { "TEMPORARY" }
            "VIEW"
            if options.contains(.ifNotExists) { "IF NOT EXISTS" }
            if let schema = view.schemaName {
                "\(schema).\(view.name)"
            } else {
                view.name
            }
            if view.columns.count > 0 {
                "(\n"
                makeColumns(view).joined(separator: ",\n ")
                "\n)"
            }
            "AS \(view.selectStatement)"
            if !options.contains(.excludeSemicolon) {
                ";"
            }
        }
    }

    public struct CreateViewOptions: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let ifNotExists = Self(rawValue: 1 << 0)
        public static let temporary = Self(rawValue: 1 << 1)
        public static let excludeSemicolon = Self(rawValue: 1 << 3)

        public static let all: Self = [.ifNotExists, .temporary, .excludeSemicolon]
    }

}
