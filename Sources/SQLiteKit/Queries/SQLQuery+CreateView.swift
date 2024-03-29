import Foundation

extension SQLQuery {
    
    public static func createView(_ view: SQLView, options: SQLCreateViewOptions = []) -> SQLQuery {
        
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
        
        return makeQuery { () -> SQLQuery in
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
}
