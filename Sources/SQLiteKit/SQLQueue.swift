import Foundation

/// A thread-safe wrapper for SQLite database operations.
///
/// `SQLQueue` provides a safe way to perform database operations by serializing all database
/// access through a dedicated dispatch queue. This ensures thread safety and prevents concurrent
/// access issues with SQLite.
///
/// ## Usage
///
/// Open a database:
///
/// ```swift
/// let dbQueue = try SQLQueue.open(path: "/path/to/database.sqlite3")
/// ```
///
/// Execute asynchronous operations:
///
/// ```swift
/// dbQueue.run { db in
///     try db.execute(sql: "INSERT INTO users (name) VALUES (?)", values: .text("Alice"))
/// }
/// ```
///
/// Execute synchronous operations:
///
/// ```swift
/// try dbQueue.runSynchronously { db in
///     let statement = try db.prepare(statement: "SELECT * FROM users")
///     let result = try statement.step()
/// }
/// ```
///
/// ## Topics
///
/// ### Opening a Database
/// - ``open(path:)``
///
/// ### Running Operations
/// - ``run(actions:)``
/// - ``run(actions:completion:)``
/// - ``runSynchronously(actions:)``
///
/// ### Transactions
/// - ``transaction(actions:)``
/// - ``transaction(actions:completion:)``
/// - ``transactionSynchronously(actions:)``
///
/// ### Backup Operations
/// - ``storeBackup(to:vacuum:completion:)``
/// - ``storeBackupSynchronously(to:vacuum:)``
/// - ``restoreBackup(from:completion:)``
/// - ``restoreBackupSynchronously(from:)``
///
/// ### Observing Changes
/// - ``didUpdate``
public class SQLQueue {

    private let serialQueue = DispatchQueue(label: "sqlitekit.SQLAsyncDatabase")

    private let database: SQLiteDatabase

    /// A closure called when an insertion, update, or deletion has been made to the database.
    ///
    /// This hook allows you to observe changes to the database in real-time. The closure is called
    /// with the type of update, the table name (if available), and the row ID that was affected.
    ///
    /// - Note: The update hook is called even when changes are made inside a transaction, but
    ///   the changes will only be visible outside the transaction after it commits.
    ///
    /// ## Example
    ///
    /// ```swift
    /// dbQueue.didUpdate = { type, table, rowID in
    ///     print("Update: \(type) on table \(table ?? "unknown") at row \(rowID)")
    /// }
    /// ```
    public var didUpdate: ((SQLUpdateType, _ table: String?, _ rowID: Int64) -> Void)? {
        didSet {
            serialQueue.sync {
                database.setUpdateHook(didUpdate)
            }
        }
    }

    /// Opens or creates a SQLite database at the specified path.
    ///
    /// If the database file doesn't exist, it will be created. This method returns a new
    /// `SQLQueue` instance that can be used to perform thread-safe database operations.
    ///
    /// - Parameter path: The file system path to the SQLite database file.
    /// - Returns: A new `SQLQueue` instance for the opened database.
    /// - Throws: ``SQLError/failedToOpenDatabase(code:message:)`` if the database cannot be opened.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let dbQueue = try SQLQueue.open(path: "/tmp/myapp.sqlite3")
    /// ```
    public static func open(path: String) throws -> SQLQueue {
        return SQLQueue(database: try SQLiteDatabase.open(path: path))
    }

    private init(database: SQLiteDatabase) {
        self.database = database
    }

    // MARK: - Run

    /// Runs database actions asynchronously.
    ///
    /// The provided closure is executed on the internal serial queue, ensuring thread-safe
    /// access to the database. This is a fire-and-forget operation; use ``run(actions:completion:)``
    /// if you need to be notified when the operation completes.
    ///
    /// - Parameter actions: A closure that receives an ``SQLDatabase`` instance and performs
    ///   database operations. The closure may throw errors.
    ///
    /// ## Example
    ///
    /// ```swift
    /// dbQueue.run { db in
    ///     try db.execute(sql: "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)")
    /// }
    /// ```
    public func run(actions: @escaping (SQLDatabase) throws -> Void) {
        run(actions: actions, completion: nil)
    }

    /// Runs database actions asynchronously with a completion handler.
    ///
    /// The provided closure is executed on the internal serial queue. When the operation
    /// completes (successfully or with an error), the completion handler is called.
    ///
    /// - Parameters:
    ///   - actions: A closure that receives an ``SQLDatabase`` instance and performs
    ///     database operations. The closure may throw errors.
    ///   - completion: An optional closure called when the operation completes, providing
    ///     a success boolean and an optional error.
    ///
    /// ## Example
    ///
    /// ```swift
    /// dbQueue.run(
    ///     actions: { db in
    ///         try db.execute(sql: "INSERT INTO users (name) VALUES (?)", values: .text("Alice"))
    ///     },
    ///     completion: { success, error in
    ///         if success {
    ///             print("Insert successful")
    ///         } else if let error = error {
    ///             print("Error: \(error)")
    ///         }
    ///     }
    /// )
    /// ```
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

    /// Runs database actions synchronously on the internal serial queue.
    ///
    /// This method blocks the calling thread until the database operations complete.
    /// The provided closure is executed on the internal serial queue to ensure thread-safe
    /// access to the database.
    ///
    /// - Parameter actions: A closure that receives an ``SQLDatabase`` instance and performs
    ///   database operations.
    /// - Throws: Any error thrown by the actions closure, typically an ``SQLError``.
    ///
    /// ## Example
    ///
    /// ```swift
    /// try dbQueue.runSynchronously { db in
    ///     let statement = try db.prepare(statement: "SELECT COUNT(*) FROM users")
    ///     let result = try statement.step()
    ///     if case .row(let row) = result {
    ///         let count: Int? = row.value(at: 0)
    ///         print("User count: \(count ?? 0)")
    ///     }
    /// }
    /// ```
    public func runSynchronously(actions: @escaping (SQLDatabase) throws -> Void) throws {
        try serialQueue.sync { [weak self] in
            guard let database = self?.database else {
                return
            }
            try actions(database)
        }
    }

    // MARK: - Transaction

    /// Runs a database transaction asynchronously.
    ///
    /// A transaction ensures that a series of database operations are executed atomically.
    /// The transaction is automatically rolled back if an error occurs. This is a fire-and-forget
    /// operation; use ``transaction(actions:completion:)`` if you need to be notified when
    /// the transaction completes.
    ///
    /// - Parameter actions: A closure that receives an ``SQLDatabase`` instance, performs
    ///   database operations, and returns an ``SQLTransactionResult`` indicating whether
    ///   to commit or rollback the transaction.
    ///
    /// ## Example
    ///
    /// ```swift
    /// dbQueue.transaction { db in
    ///     try db.execute(sql: "UPDATE accounts SET balance = balance - 100 WHERE id = 1")
    ///     try db.execute(sql: "UPDATE accounts SET balance = balance + 100 WHERE id = 2")
    ///     return .commit
    /// }
    /// ```
    public func transaction(actions: @escaping (SQLDatabase) throws -> SQLTransactionResult) {
        transaction(actions: actions, completion: nil)
    }

    /// Runs a database transaction asynchronously with a completion handler.
    ///
    /// A transaction ensures that a series of database operations are executed atomically.
    /// The transaction is automatically rolled back if an error occurs. When the transaction
    /// completes (successfully or with an error), the completion handler is called.
    ///
    /// - Parameters:
    ///   - actions: A closure that receives an ``SQLDatabase`` instance, performs
    ///     database operations, and returns an ``SQLTransactionResult`` indicating whether
    ///     to commit or rollback the transaction.
    ///   - completion: An optional closure called when the transaction completes, providing
    ///     the transaction result and an optional error.
    ///
    /// ## Example
    ///
    /// ```swift
    /// dbQueue.transaction(
    ///     actions: { db in
    ///         try db.execute(sql: "UPDATE accounts SET balance = balance - 100 WHERE id = 1")
    ///         try db.execute(sql: "UPDATE accounts SET balance = balance + 100 WHERE id = 2")
    ///         return .commit
    ///     },
    ///     completion: { result, error in
    ///         if result == .commit && error == nil {
    ///             print("Transaction committed successfully")
    ///         }
    ///     }
    /// )
    /// ```
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

    /// Runs a database transaction synchronously on the internal serial queue.
    ///
    /// This method blocks the calling thread until the transaction completes. A transaction
    /// ensures that a series of database operations are executed atomically. The transaction
    /// is automatically rolled back if an error occurs.
    ///
    /// - Parameter actions: A closure that receives an ``SQLDatabase`` instance, performs
    ///   database operations, and returns an ``SQLTransactionResult`` indicating whether
    ///   to commit or rollback the transaction.
    /// - Returns: The ``SQLTransactionResult`` returned by the actions closure.
    /// - Throws: Any error thrown by the actions closure, typically an ``SQLError``.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let result = try dbQueue.transactionSynchronously { db in
    ///     try db.execute(sql: "UPDATE accounts SET balance = balance - 100 WHERE id = 1")
    ///     try db.execute(sql: "UPDATE accounts SET balance = balance + 100 WHERE id = 2")
    ///     return .commit
    /// }
    /// ```
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

    // MARK: - Backup

    /// Stores a backup of the database to a new SQLite database file synchronously.
    ///
    /// This method creates a copy of the current database at the specified path.
    /// The operation blocks the calling thread until the backup is complete.
    ///
    /// - Parameters:
    ///   - path: The file system path where the backup database will be created.
    ///   - vacuum: If `true`, uses the VACUUM INTO command which creates a smaller file
    ///     but is slower. If `false` (default), uses the SQLite backup API which is faster
    ///     but results in a larger file.
    /// - Throws: ``SQLError`` if the backup operation fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// try dbQueue.storeBackupSynchronously(to: "/tmp/backup.sqlite3")
    /// ```
    public func storeBackupSynchronously(to path: String, vacuum: Bool = false) throws {
        try serialQueue.sync { [database] in
            try database.storeBackup(to: path, vacuum: vacuum)
        }
    }

    /// Stores a backup of the database to a new SQLite database file asynchronously.
    ///
    /// This method creates a copy of the current database at the specified path.
    /// The operation is performed on the internal serial queue, and the completion
    /// handler is called when the backup completes.
    ///
    /// - Parameters:
    ///   - path: The file system path where the backup database will be created.
    ///   - vacuum: If `true`, uses the VACUUM INTO command which creates a smaller file
    ///     but is slower. If `false` (default), uses the SQLite backup API which is faster
    ///     but results in a larger file.
    ///   - completion: An optional closure called when the backup operation completes,
    ///     providing a `Result` indicating success or failure.
    ///
    /// ## Example
    ///
    /// ```swift
    /// dbQueue.storeBackup(to: "/tmp/backup.sqlite3") { result in
    ///     switch result {
    ///     case .success:
    ///         print("Backup created successfully")
    ///     case .failure(let error):
    ///         print("Backup failed: \(error)")
    ///     }
    /// }
    /// ```
    public func storeBackup(to path: String, vacuum: Bool = false, completion: ((Result<(), SQLError>) -> Void)?) {
        serialQueue.async { [weak self] in
            guard let database = self?.database else {
                return
            }
            do {
                try database.storeBackup(to: path, vacuum: vacuum)
            } catch let error as SQLError {
                completion?(.failure(error))
                return
            } catch {
                fatalError("SQLQueue run failed from unknown error.")
            }
            
            completion?(.success(Void()))
        }
    }

    /// Restores the database from a backup file synchronously.
    ///
    /// This method replaces the current database contents with the contents from
    /// the backup database at the specified path. The operation blocks the calling
    /// thread until the restore is complete.
    ///
    /// - Parameter path: The file system path to the backup database file.
    /// - Throws: ``SQLError`` if the restore operation fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// try dbQueue.restoreBackupSynchronously(from: "/tmp/backup.sqlite3")
    /// ```
    ///
    /// - Warning: This operation will overwrite the current database contents.
    public func restoreBackupSynchronously(from path: String) throws {
        try serialQueue.sync { [database] in
            try database.restoreBackup(from: path)
        }
    }

    /// Restores the database from a backup file asynchronously.
    ///
    /// This method replaces the current database contents with the contents from
    /// the backup database at the specified path. The operation is performed on the
    /// internal serial queue, and the completion handler is called when the restore completes.
    ///
    /// - Parameters:
    ///   - path: The file system path to the backup database file.
    ///   - completion: An optional closure called when the restore operation completes,
    ///     providing a `Result` indicating success or failure.
    ///
    /// ## Example
    ///
    /// ```swift
    /// dbQueue.restoreBackup(from: "/tmp/backup.sqlite3") { result in
    ///     switch result {
    ///     case .success:
    ///         print("Database restored successfully")
    ///     case .failure(let error):
    ///         print("Restore failed: \(error)")
    ///     }
    /// }
    /// ```
    ///
    /// - Warning: This operation will overwrite the current database contents.
    public func restoreBackup(from path: String, completion: ((Result<(), SQLError>) -> Void)?) {
        serialQueue.async { [weak self] in
            guard let database = self?.database else {
                return
            }
            do {
                try database.restoreBackup(from: path)
            } catch let error as SQLError {
                completion?(.failure(error))
                return
            } catch {
                fatalError("SQLQueue run failed from unknown error.")
            }
            
            completion?(.success(Void()))
        }
    }
}
