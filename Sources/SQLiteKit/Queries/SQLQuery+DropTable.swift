import Foundation

extension SQLQuery {
    
    public static func dropTable(_ table: SQLTable, options: SQLDropOptions = []) -> SQLQuery {
        makeQuery { () -> SQLQuery in
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
}
