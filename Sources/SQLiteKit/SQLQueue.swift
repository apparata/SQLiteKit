import Foundation

public class SQLQueue {
    
    private let serialQueue = DispatchQueue(label: "sqlitekit.SQLAsyncDatabase")
    
    private let database: SQLiteDatabase
    
    /// Called when an insertion, update, or deletion has been made.
    public var didUpdate: ((SQLUpdateType, _ table: String?, _ rowID: Int64) -> Void)? {
        didSet {
            serialQueue.sync {
                database.setUpdateHook(didUpdate)
            }
        }
    }
    
    /// Opens the SQLite database at path.
    public static func open(path: String) throws -> SQLQueue {
        return SQLQueue(database: try SQLiteDatabase.open(path: path))
    }
    
    private init(database: SQLiteDatabase) {
        self.database = database
    }
    
    /// Runs database actions asynchronously.
    public func run(actions: @escaping (SQLDatabase) throws -> Void) {
        run(actions: actions, completion: nil)
    }
    
    /// Runs database actions asynchronously with a completion handler.
    public func run(actions: @escaping (SQLDatabase) throws -> Void,
                    completion: ((_ success: Bool, _ error: SQLError?) -> Void)?) {
        serialQueue.async { [weak self] in
            guard let database = self?.database else {
                return
            }
            do {
                try actions(database)
            } catch let error as SQLError {
                completion?(false, error)
                return
            } catch {
                fatalError("SQLQueue run failed from unknown error.")
            }
            
            completion?(true, nil)
        }
    }
    
    /// Runs database actions synchronously.
    public func runSynchronously(actions: @escaping (SQLDatabase) throws -> Void) throws {
        try serialQueue.sync { [weak self] in
            guard let database = self?.database else {
                return
            }
            try actions(database)
        }
    }
    
    /// Runs a database transaction asynchronously.
    public func transaction(actions: @escaping (SQLDatabase) throws -> SQLTransactionResult) {
        transaction(actions: actions, completion: nil)
    }

    /// Runs a database transaction asynchronously with a completion handler.
    public func transaction(actions: @escaping (SQLDatabase) throws -> SQLTransactionResult,
                            completion: ((_ result: SQLTransactionResult, _ error: SQLError?) -> Void)?) {
        serialQueue.async { [weak self] in
            guard let database = self?.database else {
                return
            }
            let result: SQLTransactionResult
            do {
                result = try database.transaction(actions)
            } catch let error as SQLError {
                completion?(.rollback, error)
                return
            } catch {
                fatalError("SQLQueue run failed from unknown error.")
            }
            
            completion?(result, nil)
        }
    }
    
    /// Runs a database transaction synchronously.
    @discardableResult
    public func transactionSynchronously(actions: @escaping (SQLDatabase) throws -> SQLTransactionResult) throws -> SQLTransactionResult {
        let result = try serialQueue.sync { [weak self] () -> SQLTransactionResult in
            guard let database = self?.database else {
                return .rollback
            }
            let result = try database.transaction(actions)
            return result
        }
        return result
    }
}
