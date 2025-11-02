import Foundation

/// A protocol representing a column in a SQL table.
public protocol SQLTableColumn {
    /// The name of the column.
    var name: String { get }
    /// The data type of the column.
    var dataType: SQLColumnCompatibleType.Type { get }
    /// Whether the column has a NOT NULL constraint.
    var notNullable: Bool { get }
    /// The conflict resolution method for the NOT NULL constraint.
    var notNullableOnConflict: SQLConflictResolutionType? { get }
    /// The default value for the column as a string.
    var defaultToAsString: String? { get }
    /// The collation name for the column.
    var collationName: String? { get }
    /// The expression for a generated column.
    var generatedAsExpression: SQLExpression? { get }
    /// Whether the generated column is stored.
    var generatedAsStored: Bool { get }
}

// MARK: - SQLColumn

/// A declarative representation of a table column.
///
/// `SQLColumn` provides a type-safe way to define table columns with constraints.
/// It's used within the ``SQLTable`` DSL to build table schemas.
///
/// ## Usage
///
/// Basic column definition:
///
/// ```swift
/// SQLColumn("name", String.self)
/// SQLColumn("age", Int.self)
/// SQLColumn("weight", Double.self)
/// ```
///
/// Column with constraints:
///
/// ```swift
/// SQLColumn("id", Int.self).notNull()
/// SQLColumn("email", String.self).notNull().defaultTo("unknown@example.com")
/// SQLColumn("created_at", Int.self).defaultTo(SQLExpression("CURRENT_TIMESTAMP"))
/// ```
///
/// ## Topics
///
/// ### Creating Columns
/// - ``init(_:_:)``
///
/// ### Properties
/// - ``name``
/// - ``type``
/// - ``constraints``
///
/// ### Constraints
/// - ``notNull(onConflict:)``
/// - ``defaultTo(_:)-7v8ht``
/// - ``defaultTo(_:)-3s5zr``
/// - ``collateUsing(_:)``
/// - ``generatedAs(_:store:)``
public struct SQLColumn<T: SQLColumnCompatibleType> {

    /// The name of the column.
    public let name: SQLColumnName
    /// The Swift type of the column.
    public let type: T.Type
    /// The column constraints.
    public private(set) var constraints: Constraints

    /// Creates a new column definition.
    ///
    /// - Parameters:
    ///   - name: The name of the column.
    ///   - type: The Swift type that corresponds to the SQLite column type.
    public init(_ name: SQLColumnName, _ type: T.Type) {
        self.name = name
        self.type = type
        self.constraints = Constraints()
    }
    
    public func notNull(onConflict: SQLConflictResolutionType? = nil) -> SQLColumn {
        let notNullable = NotNullable(onConflict: onConflict)
        let newConstraints = constraints.replacing(\.notNull, with: notNullable)
        return replacing(\.constraints, with: newConstraints)
    }
        
    public func defaultTo(_ value: T) -> SQLColumn {
        replacingConstraint(\.defaultTo, with: .value(value))
    }
    
    public func defaultTo(_ expression: SQLExpression) -> SQLColumn {
        replacingConstraint(\.defaultTo, with: .expression(expression))
    }
        
    public func collateUsing(_ collationName: String) -> SQLColumn {
        replacingConstraint(\.collationName, with: collationName)
    }
    
    public func generatedAs(_ expression: SQLExpression, store: Bool = false) -> SQLColumn {
        let generatedAs = GeneratedAs(expression: expression, isStored: store)
        return replacingConstraint(\.generatedAs, with: generatedAs)
    }
}

extension SQLColumn: SQLTableColumn {
    public var dataType: SQLColumnCompatibleType.Type {
        type as SQLColumnCompatibleType.Type
    }
    
    public var notNullable: Bool { constraints.notNull != nil }
    public var notNullableOnConflict: SQLConflictResolutionType? { constraints.notNull?.onConflict }
    public var collationName: String? { constraints.collationName }
    public var generatedAsExpression: SQLExpression? { constraints.generatedAs?.expression }
    public var generatedAsStored: Bool { constraints.generatedAs?.isStored ?? false }
    public var defaultToAsString: String? {
        switch constraints.defaultTo {
        case .value(let value): return value.queryStringValue
        case .expression(let expression): return "(\(expression))"
        case .none: return nil
        }
    }
}

// MARK: - Constraints

extension SQLColumn {
    public struct Constraints {
        public var notNull: NotNullable?
        public var defaultTo: DefaultTo?
        public var collationName: String?
        public var generatedAs: GeneratedAs?
    }
}

extension SQLColumn {
    public struct NotNullable {
        public let onConflict: SQLConflictResolutionType?
    }
}

extension SQLColumn {
    public enum DefaultTo {
        case value(T)
        case expression(SQLExpression)
    }
}

extension SQLColumn {
    public struct GeneratedAs {
        public var expression: SQLExpression
        public var isStored: Bool
    }
}

// MARK: - Extensions

extension SQLColumn: KeyPathReplaceable {
    private func replacingConstraint<LeafType>(_ keyPath: WritableKeyPath<Constraints, LeafType>, with value: LeafType) -> SQLColumn {
        replacing(\.constraints, with: constraints.replacing(keyPath, with: value))
    }
}

extension SQLColumn.Constraints: KeyPathReplaceable { }
