
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

public typealias SQLQueryString = String

public struct SQLQuery {
    
    var string: SQLQueryString
    
    public init(_ string: String) {
        self.string = string
    }
    
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
        
        return makeQuery {
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
                "\n)"
            }
            if let primaryKey = table.constraints.primaryKey {
                "PRIMARY KEY ("
                primaryKey.columns
                ")"
                if let onConflict = primaryKey.onConflict {
                    "ON CONFLICT"
                    onConflict
                }
            }
            if let uniqueColumns = table.constraints.uniqueColumns {
                "UNIQUE ("
                uniqueColumns.columns
                ")"
                if let onConflict = uniqueColumns.onConflict {
                    "ON CONFLICT"
                    onConflict
                }
            }
            if let checkExpression = table.constraints.check {
                "CHECK ("
                checkExpression
                ")"
            }
            if !options.contains(.excludeSemicolon) {
                ";"
            }
        }
    }
        
    public static func dropTable(_ table: SQLTable) -> SQLQuery {
        Self("DROP TABLE \(table.name)")
    }
}

extension SQLQuery {
    private static func makeQuery(@SQLQueryStringBuilder _ string: () -> SQLQuery) -> SQLQuery {
        return string()
    }
}

extension SQLQuery: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.string = value
    }
}
