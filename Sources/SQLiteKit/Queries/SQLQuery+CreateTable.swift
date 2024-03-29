import Foundation

extension SQLQuery {
    
    public static func createTable(_ table: SQLTable, options: SQLCreateTableOptions = []) -> SQLQuery {
        
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
        func makeColumns(_ table: SQLTable) -> [String] {
            for column in table.columns {
                makeColumn(column)
            }
        }
        
        return makeQuery { () -> SQLQuery in
            "CREATE"
            if options.contains(.temporary) { "TEMPORARY" }
            "TABLE"
            if options.contains(.ifNotExists) { "IF NOT EXISTS" }
            if let schema = table.schemaName {
                "\(schema).\(table.name)"
            } else {
                table.name
            }
            if let selectStatement = table.selectStatement {
                "AS \(selectStatement)"
            } else {
                "(\n"
                makeColumns(table).joined(separator: ",\n ")
                if let primaryKey = table.constraints.primaryKey {
                    ", \n"
                    "PRIMARY KEY ("
                    primaryKey.columns
                    ")"
                    if let onConflict = primaryKey.onConflict {
                        "ON CONFLICT"
                        onConflict
                    }
                }
                if let uniqueColumns = table.constraints.uniqueColumns {
                    ", \n"
                    "UNIQUE ("
                    uniqueColumns.columns
                    ")"
                    if let onConflict = uniqueColumns.onConflict {
                        "ON CONFLICT"
                        onConflict
                    }
                }
                if let checkExpression = table.constraints.check {
                    ", \n"
                    "CHECK ("
                    checkExpression
                    ")"
                }

                "\n)"
            }
            if options.contains(.withoutRowID) {
                "WITHOUT ROWID"
            }
            if !options.contains(.excludeSemicolon) {
                ";"
            }
        }
    }
}
