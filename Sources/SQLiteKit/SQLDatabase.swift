//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation

/// The public interface to the database.
public protocol SQLDatabase: AnyObject {
    
    /// Version number of the schema of the current database.
    /// A new schema version means something has changed in
    /// the structure of the database, such as a new table,
    /// a removed column, a renamed column, or similar.
    var schemaVersion: Int? { get set }
    
    /// The ID of the last inserted row.
    /// Does not apply to `WITHOUT_ROWID` tables.
    /// The variable is updated even if the insert is rolled back.
    ///
    /// See https://www.sqlite.org/c3ref/last_insert_rowid.html
    /// for details.
    var lastInsertedRowID: Int64 { get }
    
    // MARK: - Prepared Statements
    
    /// Prepares an SQLStatement to be executed later.
    func prepare(statement sql: String) throws -> SQLStatement
    
    // MARK: - Execute
    
    /// Runs an SQL statement.
    /// Convenience wrapper around prepare, step, and finalize.
    /// This is not meant for SELECT queries as no result will be returned.
    func execute(sql: String) throws

    /// Runs an SQL statement.
    /// Convenience wrapper around prepare, bind, step, and finalize.
    /// This is not meant for SELECT queries as no result will be returned.
    func execute(sql: String, values: SQLValue...) throws
    
    /// Runs an SQL statement.
    /// Convenience wrapper around prepare, bind, step, and finalize.
    /// This is not meant for SELECT queries as no result will be returned.
    func execute(sql: String, values: [SQLValue]) throws
    
    /// Runs an SQL statement represented by an `SQLQuery` object.
    /// Convenience wrapper around prepare, bind, step, and finalize.
    /// This is not meant for SELECT queries as no result will be returned.
    func executeQuery(_ query: SQLQuery) throws
    
    // MARK: - Table Convenience
    
    /// Creates a table synchronously.
    /// This is the same as:
    /// ```
    /// executeQuery(SQLQuery.createTable(table))
    /// ```
    func createTable(_ table: SQLTable) throws

    /// Creates a table synchronously.
    /// This is the same as:
    /// ```
    /// executeQuery(SQLQuery.createTable(table, options: options))
    /// ```
    func createTable(_ table: SQLTable, options: SQLCreateTableOptions) throws
    
    /// Drops a table synchronously.
    /// This is the same as:
    /// ```
    /// executeQuery(SQLQuery.dropTable(table))
    /// ```
    func dropTable(_ table: SQLTable) throws
    
    /// Drops a table synchronously.
    /// This is the same as:
    /// ```
    /// executeQuery(SQLQuery.dropTable(table, options: options))
    /// ```
    func dropTable(_ table: SQLTable, options: SQLDropOptions) throws
    
    // MARK: - View Convenience
    
    /// Creates a view synchronously.
    /// This is the same as:
    /// ```
    /// executeQuery(SQLQuery.createView(view))
    /// ```
    func createView(_ view: SQLView) throws

    /// Creates a view synchronously.
    /// This is the same as:
    /// ```
    /// executeQuery(SQLQuery.createView(view, options: options))
    /// ```
    func createView(_ view: SQLView, options: SQLCreateViewOptions) throws

    /// Drops a view synchronously.
    /// This is the same as:
    /// ```
    /// executeQuery(SQLQuery.dropView(view))
    /// ```
    func dropView(_ view: SQLView) throws
    
    /// Drops a view synchronously.
    /// This is the same as:
    /// ```
    /// executeQuery(SQLQuery.dropView(view, options: options))
    /// ```
    func dropView(_ view: SQLView, options: SQLDropOptions) throws
}
