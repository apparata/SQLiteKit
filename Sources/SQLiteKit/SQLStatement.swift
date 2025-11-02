import Foundation
#if !os(Linux)
import os.log
#endif
import libsqlite3

/// A prepared SQL statement that can be executed multiple times with different parameters.
///
/// `SQLStatement` represents a compiled SQL statement that can be bound with values
/// and executed efficiently. Prepared statements are particularly useful when executing
/// the same SQL statement multiple times with different parameters, as the SQL is compiled
/// only once.
///
/// ## Usage
///
/// Prepare a statement:
///
/// ```swift
/// let statement = try db.prepare(statement: "INSERT INTO users (name, age) VALUES (?, ?)")
/// ```
///
/// Bind values and execute:
///
/// ```swift
/// try statement.bind(values: .text("Alice"), .int(30))
/// try statement.step()
/// ```
///
/// Execute multiple times with different values:
///
/// ```swift
/// try statement.resetBindAndStep(values: .text("Bob"), .int(25))
/// try statement.resetBindAndStep(values: .text("Charlie"), .int(35))
/// ```
///
/// - Note: The statement is automatically finalized when it's deallocated.
///
/// ## Topics
///
/// ### Binding Values
/// - ``bind(values:)-9dy9k``
/// - ``bind(values:)-9me7x``
///
/// ### Executing Statements
/// - ``step()``
/// - ``stepAllRows()``
/// - ``reset()``
///
/// ### Convenience Methods
/// - ``resetBindAndStep(values:)-8tsgv``
/// - ``resetBindAndStep(values:)-6bmxm``
/// - ``resetBindAndStepAllRows(values:)-920i5``
/// - ``resetBindAndStepAllRows(values:)-5w9xb``
///
/// ### Result Types
/// - ``StepResult``
public class SQLStatement {

    /// The result of executing a statement step.
    public enum StepResult {
        /// The statement has finished executing with no more rows.
        case done
        /// The statement has produced a row of data.
        case row(SQLRow)
    }
    
    private let statementID: SQLStatementID
    
    internal weak var errorMessage: SQLErrorMessage?
    
    internal init(id: SQLStatementID) {
        statementID = id
    }
    
    deinit {
        let status = sqlite3_finalize(statementID)
        guard status == SQLITE_OK else {
            let message = errorMessage?.current ?? "Unknown error."
            #if !os(Linux)
            os_log("%@", log: .default, type: .error, "ERROR: Failed to finalize statement: \(message)")
            #else
            print("Error: Failed to finalize statement: \(message)")
            #endif
            return
        }
    }

    /// Binds values to the prepared statement's parameters.
    ///
    /// This method binds the provided values to the statement's parameters in order.
    /// The first value is bound to the first `?` placeholder, the second value to the
    /// second `?` placeholder, and so on.
    ///
    /// - Parameter values: The values to bind to the statement's parameters.
    /// - Throws: ``SQLError/failedToBindValueToStatement(code:message:)`` if binding fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let statement = try db.prepare(statement: "INSERT INTO users (name, age) VALUES (?, ?)")
    /// try statement.bind(values: .text("Alice"), .int(30))
    /// ```
    public func bind(values: SQLValue...) throws {
        try bind(values: values)
    }

    /// Binds an array of values to the prepared statement's parameters.
    ///
    /// This method binds the provided values to the statement's parameters in order.
    /// The first value is bound to the first `?` placeholder, the second value to the
    /// second `?` placeholder, and so on.
    ///
    /// - Parameter values: An array of values to bind to the statement's parameters.
    /// - Throws: ``SQLError/failedToBindValueToStatement(code:message:)`` if binding fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let statement = try db.prepare(statement: "INSERT INTO users (name, age) VALUES (?, ?)")
    /// let values: [SQLValue] = [.text("Alice"), .int(30)]
    /// try statement.bind(values: values)
    /// ```
    public func bind(values: [SQLValue]) throws {
        for index in 0..<values.count {
            let sqlIndex = Int32(index + 1)
            var result: Int32 = SQLITE_OK
            
            switch values[index] {
            case .text(let value):
                result = sqlite3_bind_text(statementID, sqlIndex, value, -1, SQLITE_TRANSIENT)
            case .int(let value):
                result = sqlite3_bind_int64(statementID, sqlIndex, Int64(value))
            case .double(let value):
                result = sqlite3_bind_double(statementID, sqlIndex, value)
            case .blob(let value):
                _ = value.withUnsafeBytes { (bytes) -> Bool in
                    let rawPointer = bytes.baseAddress
                    result = sqlite3_bind_blob(statementID, sqlIndex, rawPointer, Int32(value.count), SQLITE_TRANSIENT)
                    return true
                }
            case .null:
                result = sqlite3_bind_null(statementID, sqlIndex)
            }
            
            guard result == SQLITE_OK else {
                throw SQLError.failedToBindValueToStatement(code: result, message: errorMessage?.current ?? "Failed to bind value to statement.")
            }
        }
    }

    /// Executes one step of the prepared statement.
    ///
    /// For statements that don't return data (INSERT, UPDATE, DELETE), this method
    /// returns ``.done`` when the statement completes. For SELECT statements, it returns
    /// ``.row(_)`` for each row of data, and ``.done`` when there are no more rows.
    ///
    /// - Returns: A ``StepResult`` indicating either completion or a row of data.
    /// - Throws: ``SQLError/failedToStepStatement(code:message:)`` if the step operation fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let statement = try db.prepare(statement: "SELECT * FROM users WHERE age > ?")
    /// try statement.bind(values: .int(18))
    ///
    /// while true {
    ///     let result = try statement.step()
    ///     switch result {
    ///     case .done:
    ///         break
    ///     case .row(let row):
    ///         let name: String? = row.value(name: "name")
    ///         print("User: \(name ?? "unknown")")
    ///     }
    /// }
    /// ```
    @discardableResult
    public func step() throws -> StepResult {
        let result = sqlite3_step(statementID)
        switch result {
        case SQLITE_DONE:
            return .done
        case SQLITE_ROW:
            return .row(try fetchCurrentRow())
        default:
            throw SQLError.failedToStepStatement(code: result, message: errorMessage?.current ?? "Failed to step statement.")
        }
    }

    /// Executes the statement and returns all rows at once.
    ///
    /// This is a convenience method that repeatedly calls ``step()`` until all rows
    /// have been retrieved. It's suitable for queries that return a manageable number
    /// of rows. For large result sets, consider using ``step()`` in a loop instead
    /// to avoid loading all data into memory at once.
    ///
    /// - Returns: An array of ``SQLRow`` objects representing all rows returned by the query.
    /// - Throws: ``SQLError/failedToStepStatement(code:message:)`` if the step operation fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let statement = try db.prepare(statement: "SELECT * FROM users")
    /// let rows = try statement.stepAllRows()
    /// for row in rows {
    ///     let name: String? = row.value(name: "name")
    ///     print("User: \(name ?? "unknown")")
    /// }
    /// ```
    public func stepAllRows() throws -> [SQLRow] {
        var rows = [SQLRow]()
        
        loop: while true {
            switch try step() {
            case .done:
                break loop
            case .row(let row):
                rows.append(row)
            }
        }

        return rows
    }

    /// Resets the prepared statement so it can be executed again.
    ///
    /// This method resets the statement to its initial state, allowing it to be
    /// re-executed. Any previously bound parameter values remain bound.
    ///
    /// - Throws: ``SQLError/failedToResetStatement(code:message:)`` if the reset operation fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let statement = try db.prepare(statement: "SELECT * FROM users WHERE age > ?")
    /// try statement.bind(values: .int(18))
    /// let rows1 = try statement.stepAllRows()
    ///
    /// // Reset and execute again with the same bound values
    /// try statement.reset()
    /// let rows2 = try statement.stepAllRows()
    /// ```
    public func reset() throws {
        let result = sqlite3_reset(statementID)
        guard result == SQLITE_OK else {
            throw SQLError.failedToResetStatement(code: result, message: errorMessage?.current ?? "Failed to reset statement.")
        }
    }

    // MARK: - Convenience

    /// Resets the statement, binds new values, and executes one step.
    ///
    /// This is a convenience method that combines ``reset()``, ``bind(values:)-9dy9k``,
    /// and ``step()`` into a single call. It's useful for executing a prepared statement
    /// multiple times with different parameter values.
    ///
    /// - Parameter values: The values to bind to the statement's parameters.
    /// - Returns: A ``StepResult`` indicating either completion or a row of data.
    /// - Throws: ``SQLError`` if any of the operations fail.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let statement = try db.prepare(statement: "INSERT INTO users (name, age) VALUES (?, ?)")
    /// try statement.resetBindAndStep(values: .text("Alice"), .int(30))
    /// try statement.resetBindAndStep(values: .text("Bob"), .int(25))
    /// try statement.resetBindAndStep(values: .text("Charlie"), .int(35))
    /// ```
    @discardableResult
    public func resetBindAndStep(values: SQLValue...) throws -> StepResult {
        return try resetBindAndStep(values: values)
    }

    /// Resets the statement, binds an array of new values, and executes one step.
    ///
    /// This is a convenience method that combines ``reset()``, ``bind(values:)-9me7x``,
    /// and ``step()`` into a single call. It's useful for executing a prepared statement
    /// multiple times with different parameter values.
    ///
    /// - Parameter values: An array of values to bind to the statement's parameters.
    /// - Returns: A ``StepResult`` indicating either completion or a row of data.
    /// - Throws: ``SQLError`` if any of the operations fail.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let statement = try db.prepare(statement: "INSERT INTO users (name, age) VALUES (?, ?)")
    /// let users = [
    ///     [SQLValue.text("Alice"), .int(30)],
    ///     [SQLValue.text("Bob"), .int(25)]
    /// ]
    /// for user in users {
    ///     try statement.resetBindAndStep(values: user)
    /// }
    /// ```
    @discardableResult
    public func resetBindAndStep(values: [SQLValue]) throws -> StepResult {
        try reset()
        try bind(values: values)
        return try step()
    }

    /// Resets the statement, binds new values, and retrieves all rows.
    ///
    /// This is a convenience method that combines ``reset()``, ``bind(values:)-9dy9k``,
    /// and ``stepAllRows()`` into a single call. It's useful for executing a SELECT
    /// statement multiple times with different parameter values.
    ///
    /// - Parameter values: The values to bind to the statement's parameters.
    /// - Returns: An array of ``SQLRow`` objects representing all rows returned by the query.
    /// - Throws: ``SQLError`` if any of the operations fail.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let statement = try db.prepare(statement: "SELECT * FROM users WHERE age > ?")
    /// let youngUsers = try statement.resetBindAndStepAllRows(values: .int(18))
    /// let olderUsers = try statement.resetBindAndStepAllRows(values: .int(30))
    /// ```
    public func resetBindAndStepAllRows(values: SQLValue...) throws -> [SQLRow] {
        return try resetBindAndStepAllRows(values: values)
    }

    /// Resets the statement, binds an array of new values, and retrieves all rows.
    ///
    /// This is a convenience method that combines ``reset()``, ``bind(values:)-9me7x``,
    /// and ``stepAllRows()`` into a single call. It's useful for executing a SELECT
    /// statement multiple times with different parameter values.
    ///
    /// - Parameter values: An array of values to bind to the statement's parameters.
    /// - Returns: An array of ``SQLRow`` objects representing all rows returned by the query.
    /// - Throws: ``SQLError`` if any of the operations fail.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let statement = try db.prepare(statement: "SELECT * FROM users WHERE age > ?")
    /// let youngUsers = try statement.resetBindAndStepAllRows(values: [.int(18)])
    /// let olderUsers = try statement.resetBindAndStepAllRows(values: [.int(30)])
    /// ```
    public func resetBindAndStepAllRows(values: [SQLValue]) throws -> [SQLRow] {
        try reset()
        try bind(values: values)
        return try stepAllRows()
    }
    
    // MARK: - Helpers
    
    private func fetchCurrentRow() throws -> SQLRow {
        
        let columnCount = sqlite3_column_count(statementID)
        guard columnCount > 0 else {
            return SQLRow()
        }
        
        var row = SQLRow()
        
        for columnIndex in 0..<columnCount {
            let columnType = sqlite3_column_type(statementID, columnIndex)
            let value: SQLValue
            
            switch columnType {
            case SQLITE_INTEGER:
                value = .int(Int(sqlite3_column_int64(statementID, columnIndex)))
            case SQLITE_FLOAT:
                value = .double(sqlite3_column_double(statementID, columnIndex))
            case SQLITE_TEXT:
                if let text = sqlite3_column_text(statementID, columnIndex) {
                    value = .text(String(cString: text))
                } else {
                    value = .null
                }
            case SQLITE_BLOB:
                if let blob = sqlite3_column_blob(statementID, columnIndex) {
                    let byteCount = sqlite3_column_bytes(statementID, columnIndex)
                    if byteCount > 0 {
                        value = .blob(Data(bytes: blob, count: Int(byteCount)))
                    } else {
                        value = .null
                    }
                } else {
                    value = .null
                }
            case SQLITE_NULL:
                value = .null
            default:
                value = .null
            }
            
            let columnName: SQLColumnName
            if let rawColumnName = sqlite3_column_name(statementID, columnIndex) {
                columnName = String(cString: rawColumnName)
            } else {
                columnName = "Column \(columnIndex)"
            }
            
            row.addColumn(name: columnName, index: columnIndex, value: value)
        }
        
        return row
    }
}
