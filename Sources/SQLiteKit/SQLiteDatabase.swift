//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation
import os.log
import libsqlite3

internal class SQLiteDatabase: SQLDatabase {
    
    public var schemaVersion: Int? {
        get {
            return fetchSchemaVersion()
        }
        set {
            if let newVersion = newValue {
                updateSchemaVersion(newVersion)
            }
        }
    }
    
    public var lastInsertedRowID: Int64 {
        return fetchLastInsertedRowID()
    }
    
    private let db: SQLDatabaseID

    private var updateHook: UpdateHook?
    
    internal var errorMessage: String {
        return String(cString: sqlite3_errmsg(db))
    }
    
    internal typealias Statement = OpaquePointer
    
    internal init(id: SQLDatabaseID) {
        db = id
    }
    
    deinit {
        sqlite3_update_hook(db, nil, nil)
        sqlite3_close(db)
    }
    
    public static func open(path: String) throws -> SQLiteDatabase {
        var db: SQLDatabaseID? = nil
        
        let result = sqlite3_open(path, &db)
        if result == SQLITE_OK, let db = db {
            return SQLiteDatabase(id: db)
        }
        
        // Failed to open database. Do cleanup and throw error.
        
        let message = String(cString: sqlite3_errmsg(db))
        
        if let db = db {
            sqlite3_close(db)
        }
        
        throw SQLError.failedToOpenDatabase(code: result, message: message)
    }
    
    public func prepare(statement sql: String) throws -> SQLStatement {
        var preparedStatement: Statement? = nil
        
        let result = sqlite3_prepare_v2(db, sql, -1, &preparedStatement, nil)
        guard result == SQLITE_OK else {
            throw SQLError.failedToPrepareStatement(code: result, message: errorMessage)
        }
        
        guard let statement = preparedStatement else {
            throw SQLError.failedToPrepareStatement(code: SQLITE_INTERNAL, message: "Failed to prepare statement.")
        }
        
        let sqlStatement = SQLStatement(id: statement)
        sqlStatement.errorMessage = self
        
        return sqlStatement
    }
    
    /// Convenience wrapper around prepare, step, and finalize.
    public func execute(sql: String) throws {
        try execute(sql: sql, values: [])
    }
    
    /// Convenience wrapper around prepare, bind, step, and finalize.
    public func execute(sql: String, values: SQLValue...) throws {
        try execute(sql: sql, values: values)
    }
    
    /// Convenience wrapper around prepare, bind, step, and finalize.
    public func execute(sql: String, values: [SQLValue]) throws {
        let statement = try prepare(statement: sql)
        
        if values.count > 0 {
            try statement.bind(values: values)
        }
        
        try statement.step()
    }

    internal func transaction(_ actions: (SQLDatabase) throws -> SQLTransactionResult) throws -> SQLTransactionResult {
        
        try execute(sql: "BEGIN EXCLUSIVE")
        
        let result: SQLTransactionResult
        do {
            result = try actions(self)
        } catch let error as SQLError {
            do {
                try execute(sql: "ROLLBACK")
            } catch {
                // Let's just swallow this error and return the original error.
            }
            throw error
        }
        
        switch result {
        case .commit:
            try execute(sql: "COMMIT")
        case .rollback:
            try execute(sql: "ROLLBACK")
        }
        
        return result
    }
    
    func fetchSchemaVersion() -> Int? {
        do {
            let statement = try prepare(statement: "PRAGMA user_version;")
            let result = try statement.step()
            if case .row(let row) = result {
                if let version: Int = row.value(at: 0) {
                    return Int(version)
                }
            }
        } catch let error {
            os_log("%@", log: .default, type: .error, "Failed to fetch database schema. \(error)")
        }
        return nil
    }
    
    func updateSchemaVersion(_ newVersion: Int) {
        do {
            let statement = try prepare(statement: "PRAGMA user_version = \(newVersion);")
            try statement.step()
        } catch let error {
            os_log("%@", log: .default, type: .error, "Failed to update database schema. \(error)")
        }
    }
    
    func fetchLastInsertedRowID() -> Int64 {
        return sqlite3_last_insert_rowid(db)
    }
    
    func setUpdateHook(_ hook: ((SQLUpdateType, _ table: String?, _ rowID: Int64) -> Void)?) -> Void {
        if let hook = hook {
            let updateHook = UpdateHook(hook)
            self.updateHook = updateHook
            sqlite3_update_hook(db, { (rawHook: UnsafeMutableRawPointer?, updateType, _, table, rowID) in
                guard let rawHook = rawHook else {
                    return
                }
                let updateHook = Unmanaged<UpdateHook>.fromOpaque(rawHook).takeUnretainedValue()
                let type: SQLUpdateType
                switch updateType {
                case SQLITE_INSERT: type = .insert
                case SQLITE_UPDATE: type = .update
                case SQLITE_DELETE: type = .delete
                default: return
                }
                updateHook.call(type, table.map { String(cString: $0) }, rowID)
            }, Unmanaged<UpdateHook>.passUnretained(updateHook).toOpaque())
        } else {
            sqlite3_update_hook(db, nil, nil)
        }
    }
}

extension SQLiteDatabase: SQLErrorMessage {
    
    var current: String {
        return errorMessage
    }
}

private class UpdateHook {
    let hook: (SQLUpdateType, _ table: String?, _ rowID: Int64) -> Void
    
    init(_ hook: @escaping (SQLUpdateType, _ table: String?, _ rowID: Int64) -> Void) {
        self.hook = hook
    }
    
    func call(_ type: SQLUpdateType, _ table: String?, _ rowID: Int64) {
        hook(type, table, rowID)
    }
}
