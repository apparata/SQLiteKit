import Foundation

/// The result of a database transaction.
///
/// This enum is returned from transaction closures to indicate whether the transaction
/// should be committed or rolled back.
///
/// ## Usage
///
/// ```swift
/// dbQueue.transaction { db in
///     try db.execute(sql: "INSERT INTO users (name) VALUES (?)", values: .text("Alice"))
///
///     // Decide whether to commit or rollback
///     if someCondition {
///         return .commit    // Commit the transaction
///     } else {
///         return .rollback  // Rollback the transaction
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Result Types
/// - ``rollback``
/// - ``commit``
public enum SQLTransactionResult {
    /// Roll back the transaction, discarding all changes.
    case rollback
    /// Commit the transaction, making all changes permanent.
    case commit
}
