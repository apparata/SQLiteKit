import Foundation

/// A SQL table name.
public typealias SQLTableName = String

// MARK: - SQLTable

/// A declarative representation of a SQLite table.
///
/// `SQLTable` provides a Swift-based DSL for defining table structures. It can be
/// used to generate CREATE TABLE and DROP TABLE queries using the query builder API.
///
/// ## Usage
///
/// Define a table with columns:
///
/// ```swift
/// let users = SQLTable("users") {
///     SQLColumn("id", Int.self).notNull()
///     SQLColumn("name", String.self).notNull()
///     SQLColumn("email", String.self)
///     SQLColumn("age", Int.self)
/// }
/// .primaryKey("id")
/// .unique("email")
/// ```
///
/// Create the table:
///
/// ```swift
/// try db.createTable(users)
/// // or
/// try db.executeQuery(SQLQuery.createTable(users))
/// ```
///
/// Define a table based on a SELECT statement:
///
/// ```swift
/// let activeUsers = SQLTable("active_users", as: "SELECT * FROM users WHERE active = 1")
/// ```
///
/// ## Topics
///
/// ### Creating Tables
/// - ``init(_:columns:)``
/// - ``init(_:as:)``
///
/// ### Properties
/// - ``name``
/// - ``columns``
/// - ``selectStatement``
/// - ``schemaName``
/// - ``constraints``
///
/// ### Constraints
/// - ``primaryKey(_:onConflict:)-9zv87``
/// - ``primaryKey(_:onConflict:)-8i87y``
/// - ``unique(_:onConflict:)-2qjxf``
/// - ``unique(_:onConflict:)-5b3r3``
/// - ``check(_:)``
///
/// ### Schema Configuration
/// - ``schema(_:)``
public struct SQLTable {

    /// The name of the table.
    public let name: SQLTableName
    /// The columns in the table.
    public let columns: [SQLTableColumn]
    /// The SELECT statement for tables created from a query.
    public let selectStatement: String?
    /// The schema name for the table (optional).
    public private(set) var schemaName: String?
    /// The table-level constraints.
    public private(set) var constraints: Constraints

    /// Creates a table definition with columns.
    ///
    /// - Parameters:
    ///   - name: The name of the table.
    ///   - columns: A result builder closure that defines the table's columns.
    public init(_ name: SQLTableName, @SQLTableBuilder columns: () -> [SQLTableColumn]) {
        self.name = name
        self.columns = columns()
        selectStatement = nil
        constraints = Constraints()
    }

    /// Creates a table definition based on a SELECT statement.
    ///
    /// This creates a table that will be populated from the results of a SELECT query.
    ///
    /// - Parameters:
    ///   - name: The name of the table.
    ///   - selectStatement: A SQL SELECT statement that defines the table's contents.
    public init(_ name: SQLTableName, as selectStatement: String) {
        self.name = name
        columns = []
        self.selectStatement = selectStatement
        constraints = Constraints()
    }
    
    public func schema(_ name: String) -> SQLTable {
        replacing(\.schemaName, with: name)
    }
        
    public func primaryKey(_ columnNames: [SQLColumnName],
                           onConflict: SQLConflictResolutionType? = nil) -> SQLTable {
        let primaryKey = PrimaryKey(columns: columnNames, onConflict: onConflict)
        return replacingConstraint(\.primaryKey, with: primaryKey)
    }
    
    public func primaryKey(_ columnNames: SQLColumnName...,
                           onConflict: SQLConflictResolutionType? = nil) -> SQLTable {
        primaryKey(columnNames, onConflict: onConflict)
    }

    public func unique(_ columnNames: [SQLColumnName],
                       onConflict: SQLConflictResolutionType? = nil) -> SQLTable {
        let uniqueColumns = UniqueColumns(columns: columnNames, onConflict: onConflict)
        return replacingConstraint(\.uniqueColumns, with: uniqueColumns)
    }
    
    public func unique(_ columnNames: SQLColumnName...,
                       onConflict: SQLConflictResolutionType? = nil) -> SQLTable {
        primaryKey(columnNames, onConflict: onConflict)
    }
    
    public func check(_ expression: SQLExpression) -> SQLTable {
        replacingConstraint(\.check, with: expression)
    }
}

// MARK: - Constraints

extension SQLTable {
    public struct Constraints {
        public var primaryKey: PrimaryKey?
        public var uniqueColumns: UniqueColumns?
        public var check: SQLExpression?
    }
}

extension SQLTable {
    public struct PrimaryKey {
        public let columns: [SQLColumnName]
        public let onConflict: SQLConflictResolutionType?
    }
}

extension SQLTable {
    public struct UniqueColumns {
        public let columns: [SQLColumnName]
        public let onConflict: SQLConflictResolutionType?
    }
}

// MARK: - Extensions

extension SQLTable: KeyPathReplaceable {
    func replacingConstraint<LeafType>(_ keyPath: WritableKeyPath<Constraints, LeafType>, with value: LeafType) -> SQLTable {
        replacing(\.constraints, with: constraints.replacing(keyPath, with: value))
    }
}

extension SQLTable.Constraints: KeyPathReplaceable { }
