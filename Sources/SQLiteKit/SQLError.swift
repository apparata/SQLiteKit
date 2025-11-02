import Foundation

/// The SQLite error code.
public typealias SQLErrorCode = Int32

/// Errors that can occur when working with SQLite databases.
///
/// All errors include a SQLite error code and a descriptive message from SQLite.
/// The error codes correspond to the standard SQLite result codes.
///
/// ## Topics
///
/// ### Error Cases
/// - ``failedToOpenDatabase(code:message:)``
/// - ``failedToPrepareStatement(code:message:)``
/// - ``failedToStepStatement(code:message:)``
/// - ``failedToBindValueToStatement(code:message:)``
/// - ``failedToResetStatement(code:message:)``
/// - ``failedToExecute(code:message:)``
public enum SQLError: Error {
    /// Failed to open or create a database file.
    case failedToOpenDatabase(code: SQLErrorCode, message: String)
    /// Failed to prepare a SQL statement for execution.
    case failedToPrepareStatement(code: SQLErrorCode, message: String)
    /// Failed to execute (step) a prepared statement.
    case failedToStepStatement(code: SQLErrorCode, message: String)
    /// Failed to bind a value to a statement parameter.
    case failedToBindValueToStatement(code: SQLErrorCode, message: String)
    /// Failed to reset a prepared statement.
    case failedToResetStatement(code: SQLErrorCode, message: String)
    /// Failed to execute a SQL statement.
    case failedToExecute(code: SQLErrorCode, message: String)
}
