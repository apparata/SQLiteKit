import Foundation

/// Represents a value that can be stored in or retrieved from a SQLite database.
///
/// SQLite has a dynamic type system where each value has one of five storage classes:
/// `NULL`, `INTEGER`, `REAL`, `TEXT`, or `BLOB`. The `SQLValue` enum represents these
/// types in Swift.
///
/// ## Usage
///
/// Creating values:
///
/// ```swift
/// let textValue: SQLValue = .text("Hello")
/// let intValue: SQLValue = .int(42)
/// let doubleValue: SQLValue = .double(3.14)
/// let blobValue: SQLValue = .blob(Data([1, 2, 3]))
/// let nullValue: SQLValue = .null
/// ```
///
/// Using values in queries:
///
/// ```swift
/// try db.execute(sql: "INSERT INTO users (name, age) VALUES (?, ?)",
///                values: .text("Alice"), .int(30))
/// ```
///
/// ## Topics
///
/// ### Value Types
/// - ``text(_:)``
/// - ``int(_:)``
/// - ``double(_:)``
/// - ``blob(_:)``
/// - ``null``
public enum SQLValue {
    /// A text (string) value.
    case text(String)
    /// An integer value.
    case int(Int)
    /// A floating-point (double) value.
    case double(Double)
    /// A binary data (blob) value.
    case blob(Data)
    /// A NULL value.
    case null
}
