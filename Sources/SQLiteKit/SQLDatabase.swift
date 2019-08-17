//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation

/// The public interface to the database.
public protocol SQLDatabase: class {
    
    /// Version number of the schema of the current database.
    /// A new schema version means something has changed in
    /// the structure of the database, such as a new table,
    /// a removed column, a renamed column, or similar.
    var schemaVersion: Int? { get set }
    
    /// The ID of the last inserted row.
    /// Does not apply to `WITHOUT_ROWID` tables.
    /// The variable is updated even if the insert is rolled back.
    ///
    /// See https://www.sqlite.org/c3ref/last_insert_rowid.html
    /// for details.
    var lastInsertedRowID: Int64 { get }
    
    /// Prepares an SQLStatement to be executed later.
    func prepare(statement sql: String) throws -> SQLStatement
    
    /// Runs an SQL statement.
    /// Convenience wrapper around prepare, step, and finalize.
    /// This is not meant for queries as no result will be returned.
    func execute(sql: String) throws

    /// Runs an SQL statement.
    /// Convenience wrapper around prepare, bind, step, and finalize.
    /// This is not meant for queries as no result will be returned.
    func execute(sql: String, values: SQLValue...) throws
    
    /// Runs an SQL statement.
    /// Convenience wrapper around prepare, bind, step, and finalize.
    /// This is not meant for queries as no result will be returned.
    func execute(sql: String, values: [SQLValue]) throws
}
