import Foundation

extension SQLiteDatabase {
    
    // MARK: - Table Convenience
    
    func createTable(_ table: SQLTable) throws {
        try executeQuery(SQLQuery.createTable(table))
    }

    func createTable(_ table: SQLTable, options: SQLCreateTableOptions) throws {
        try executeQuery(SQLQuery.createTable(table, options: options))
    }
    
    func dropTable(_ table: SQLTable) throws {
        try executeQuery(SQLQuery.dropTable(table))
    }
    
    func dropTable(_ table: SQLTable, options: SQLDropOptions) throws {
        try executeQuery(SQLQuery.dropTable(table, options: options))
    }
    
    // MARK: - View Convenience
    
    func createView(_ view: SQLView) throws {
        try executeQuery(SQLQuery.createView(view))
    }

    func createView(_ view: SQLView, options: SQLCreateViewOptions) throws {
        try executeQuery(SQLQuery.createView(view, options: options))
    }

    func dropView(_ view: SQLView) throws {
        try executeQuery(SQLQuery.dropView(view))
    }
    
    func dropView(_ view: SQLView, options: SQLDropOptions) throws {
        try executeQuery(SQLQuery.dropView(view, options: options))
    }
}
