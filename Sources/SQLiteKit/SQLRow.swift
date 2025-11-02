import Foundation

/// Represents a single row of data returned from a SQLite query.
///
/// `SQLRow` provides access to column values by index or by column name. It acts
/// as a container for the data in a single row of a query result.
///
/// ## Usage
///
/// Accessing values by index:
///
/// ```swift
/// let statement = try db.prepare(statement: "SELECT name, age FROM users")
/// let result = try statement.step()
/// if case .row(let row) = result {
///     let name = row[0]        // First column
///     let age = row[1]         // Second column
/// }
/// ```
///
/// Accessing values by column name:
///
/// ```swift
/// if case .row(let row) = result {
///     if let nameValue = row["name"] {
///         // Use nameValue
///     }
/// }
/// ```
///
/// Using typed value extraction:
///
/// ```swift
/// if case .row(let row) = result {
///     let name: String? = row.value(name: "name")
///     let age: Int? = row.value(name: "age")
/// }
/// ```
///
/// ## Topics
///
/// ### Accessing Values
/// - ``subscript(_:)-7ojfe``
/// - ``subscript(_:)-8g8ob``
/// - ``value(at:)``
/// - ``value(name:)``
///
/// ### Properties
/// - ``columnCount``
public struct SQLRow {

    /// The number of columns in this row.
    public var columnCount: Int {
        return columns.count
    }

    internal typealias ColumnIndex = Int32

    internal var columnsByName = [SQLColumnName: ColumnIndex]()
    internal var columns = [SQLValue]()

    internal mutating func addColumn(name: SQLColumnName, index: ColumnIndex, value: SQLValue) {
        columnsByName[name] = index
        columns.append(value)
    }

    /// Accesses the value at the specified column index.
    ///
    /// - Parameter index: The zero-based index of the column.
    /// - Returns: The ``SQLValue`` at the specified index.
    public subscript(_ index: Int) -> SQLValue {
        return columns[index]
    }

    /// Accesses the value for the specified column name.
    ///
    /// - Parameter columnName: The name of the column.
    /// - Returns: The ``SQLValue`` for the specified column, or `nil` if the column doesn't exist.
    public subscript(_ columnName: SQLColumnName) -> SQLValue? {
        if let index = columnsByName[columnName],
            Int(index) < columns.count {
            return columns[Int(index)]
        } else {
            return nil
        }
    }

    /// Extracts a typed value from the specified column index.
    ///
    /// This method attempts to extract and cast the value at the given index to the
    /// specified type `T`. It works with basic types like `String`, `Int`, `Double`, and `Data`.
    ///
    /// - Parameter index: The zero-based index of the column.
    /// - Returns: The value cast to type `T`, or `nil` if the value is NULL or cannot be cast.
    ///
    /// ## Example
    ///
    /// ```swift
    /// if case .row(let row) = result {
    ///     let name: String? = row.value(at: 0)
    ///     let age: Int? = row.value(at: 1)
    /// }
    /// ```
    public func value<T>(at index: Int) -> T? {
        switch columns[index] {
        case .int(let value):
            if let value = value as? T {
                return value
            }
        case .double(let value):
            if let value = value as? T {
                return value
            }
        case .text(let value):
            if let value = value as? T {
                return value
            }
        case .blob(let value):
            if let value = value as? T {
                return value
            }
        case .null:
            return nil
        }


        return nil
    }

    /// Extracts a typed value from the column with the specified name.
    ///
    /// This method attempts to extract and cast the value from the column with the given
    /// name to the specified type `T`. It works with basic types like `String`, `Int`,
    /// `Double`, and `Data`.
    ///
    /// - Parameter name: The name of the column.
    /// - Returns: The value cast to type `T`, or `nil` if the column doesn't exist, the value
    ///   is NULL, or the value cannot be cast to type `T`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// if case .row(let row) = result {
    ///     let name: String? = row.value(name: "name")
    ///     let age: Int? = row.value(name: "age")
    ///     let weight: Double? = row.value(name: "weight")
    /// }
    /// ```
    public func value<T>(name: SQLColumnName) -> T? {
        
        guard let columnValue = self[name] else {
            return nil
        }
        
        switch columnValue {
        case .int(let value):
            if let value = value as? T {
                return value
            }
        case .double(let value):
            if let value = value as? T {
                return value
            }
        case .text(let value):
            if let value = value as? T {
                return value
            }
        case .blob(let value):
            if let value = value as? T {
                return value
            }
        case .null:
            return nil
        }
        
        return nil
    }
}

extension SQLRow: CustomStringConvertible {
    
    public var description: String {
        var string: String = "{ "
        for (columnName, columnIndex) in columnsByName {
            let value = columns[Int(columnIndex)]
            string += "\(columnName)=\(value) "
        }
        string += "}"
        return string
    }
}
