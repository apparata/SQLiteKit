import Foundation

/// The public interface for interacting with a SQLite database.
///
/// `SQLDatabase` defines the core operations for working with a SQLite database,
/// including executing SQL statements, preparing statements, managing transactions,
/// and working with tables and views.
///
/// This protocol is implemented by the internal `SQLiteDatabase` class. Users
/// typically interact with databases through ``SQLQueue``, which provides
/// thread-safe access to an `SQLDatabase` instance.
///
/// ## Topics
///
/// ### Schema Management
/// - ``schemaVersion``
/// - ``lastInsertedRowID``
///
/// ### Prepared Statements
/// - ``prepare(statement:)``
///
/// ### Executing SQL
/// - ``execute(sql:)``
/// - ``execute(sql:values:)-2cxpe``
/// - ``execute(sql:values:)-5k5mz``
/// - ``executeQuery(_:)``
///
/// ### Table Operations
/// - ``createTable(_:)``
/// - ``createTable(_:options:)``
/// - ``dropTable(_:)``
/// - ``dropTable(_:options:)``
///
/// ### View Operations
/// - ``createView(_:)``
/// - ``createView(_:options:)``
/// - ``dropView(_:)``
/// - ``dropView(_:options:)``
public protocol SQLDatabase: AnyObject {

    /// The schema version number of the database.
    ///
    /// The schema version is stored using SQLite's `user_version` pragma. It's useful
    /// for tracking database migrations. A new schema version indicates changes in
    /// the database structure, such as new tables, removed columns, or renamed columns.
    ///
    /// Setting this value updates the database's schema version.
    var schemaVersion: Int? { get set }

    /// The row ID of the last row inserted into the database.
    ///
    /// This value is updated even if the insert is rolled back. It does not apply
    /// to `WITHOUT ROWID` tables.
    ///
    /// For more information, see the [SQLite documentation](https://www.sqlite.org/c3ref/last_insert_rowid.html).
    var lastInsertedRowID: Int64 { get }
    
    // MARK: - Prepared Statements

    /// Prepares a SQL statement for later execution.
    ///
    /// This method compiles the SQL statement and returns an ``SQLStatement`` object
    /// that can be bound with values and executed. Prepared statements are efficient
    /// when executing the same SQL multiple times with different parameters.
    ///
    /// - Parameter sql: The SQL statement string to prepare.
    /// - Returns: A prepared ``SQLStatement`` ready to be executed.
    /// - Throws: ``SQLError/failedToPrepareStatement(code:message:)`` if preparation fails.
    func prepare(statement sql: String) throws -> SQLStatement

    // MARK: - Execute

    /// Executes a SQL statement without parameters.
    ///
    /// This is a convenience method that combines prepare, step, and finalize into
    /// a single call. It's suitable for statements that don't require parameter binding.
    ///
    /// - Parameter sql: The SQL statement to execute.
    /// - Throws: ``SQLError`` if the statement fails to execute.
    ///
    /// - Note: This method is not intended for SELECT queries that return data.
    ///   Use ``prepare(statement:)`` instead for queries that return rows.
    func execute(sql: String) throws

    /// Executes a SQL statement with parameter values.
    ///
    /// This is a convenience method that combines prepare, bind, step, and finalize
    /// into a single call.
    ///
    /// - Parameters:
    ///   - sql: The SQL statement to execute, with `?` placeholders for parameters.
    ///   - values: The values to bind to the statement's parameters.
    /// - Throws: ``SQLError`` if the statement fails to execute.
    ///
    /// - Note: This method is not intended for SELECT queries that return data.
    ///   Use ``prepare(statement:)`` instead for queries that return rows.
    func execute(sql: String, values: SQLValue...) throws

    /// Executes a SQL statement with an array of parameter values.
    ///
    /// This is a convenience method that combines prepare, bind, step, and finalize
    /// into a single call.
    ///
    /// - Parameters:
    ///   - sql: The SQL statement to execute, with `?` placeholders for parameters.
    ///   - values: An array of values to bind to the statement's parameters.
    /// - Throws: ``SQLError`` if the statement fails to execute.
    ///
    /// - Note: This method is not intended for SELECT queries that return data.
    ///   Use ``prepare(statement:)`` instead for queries that return rows.
    func execute(sql: String, values: [SQLValue]) throws

    /// Executes a SQL query represented by an ``SQLQuery`` object.
    ///
    /// This is a convenience method for executing queries built using the declarative
    /// query builder API.
    ///
    /// - Parameter query: The ``SQLQuery`` to execute.
    /// - Throws: ``SQLError`` if the statement fails to execute.
    ///
    /// - Note: This method is not intended for SELECT queries that return data.
    ///   Use ``prepare(statement:)`` instead for queries that return rows.
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
