import Foundation

/// The type of database update operation.
///
/// This enum is used with the ``SQLQueue/didUpdate`` hook to identify what type
/// of operation was performed on the database.
///
/// ## Topics
///
/// ### Update Types
/// - ``insert``
/// - ``update``
/// - ``delete``
public enum SQLUpdateType {
    /// A row was inserted into a table.
    case insert
    /// An existing row was updated.
    case update
    /// A row was deleted from a table.
    case delete
}
