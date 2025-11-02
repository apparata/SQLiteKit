import Foundation

/// A SQL query string.
public typealias SQLQueryString = String

/// A SQL query that can be executed against a database.
///
/// `SQLQuery` represents a SQL statement that can be executed using the
/// ``SQLDatabase/executeQuery(_:)`` method. It can be created directly from a
/// string or built using the declarative query builder API with types like
/// ``SQLTable`` and ``SQLColumn``.
///
/// ## Usage
///
/// Creating a query from a string:
///
/// ```swift
/// let query = SQLQuery("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
/// try db.executeQuery(query)
/// ```
///
/// Using the declarative query builder:
///
/// ```swift
/// let table = SQLTable("users") {
///     SQLColumn("id", Int.self).notNull()
///     SQLColumn("name", String.self).notNull()
/// }
/// .primaryKey("id")
///
/// let query = SQLQuery.createTable(table)
/// try db.executeQuery(query)
/// ```
///
/// ## Topics
///
/// ### Creating Queries
/// - ``init(_:)``
///
/// ### Query Builders
/// - ``createTable(_:)``
/// - ``createTable(_:options:)``
/// - ``dropTable(_:)``
/// - ``dropTable(_:options:)``
/// - ``createView(_:)``
/// - ``createView(_:options:)``
/// - ``dropView(_:)``
/// - ``dropView(_:options:)``
public struct SQLQuery {

    var string: SQLQueryString

    /// Creates a new SQL query from a string.
    ///
    /// - Parameter string: The SQL query string.
    public init(_ string: String) {
        self.string = string
    }
}

extension SQLQuery {
    internal static func makeQuery(@SQLQueryStringBuilder _ string: () -> SQLQuery) -> SQLQuery {
        return string()
    }
}

extension SQLQuery: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.string = value
    }
}
