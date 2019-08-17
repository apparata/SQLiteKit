//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation
import os.log
import libsqlite3

public class SQLStatement {
    
    public enum StepResult {
        case done
        case row(SQLRow)
    }
    
    private let statementID: SQLStatementID
    
    internal weak var errorMessage: SQLErrorMessage?
    
    internal init(id: SQLStatementID) {
        statementID = id
    }
    
    deinit {
        let status = sqlite3_finalize(statementID)
        guard status == SQLITE_OK else {
            let message = errorMessage?.current ?? "Unknown error."
            os_log("%@", log: .default, type: .error, "ERROR: Failed finalize statement: \(message)")
            return
        }
    }

    public func bind(values: SQLValue...) throws {
        try bind(values: values)
    }
    
    public func bind(values: [SQLValue]) throws {
        for index in 0..<values.count {
            let sqlIndex = Int32(index + 1)
            var result: Int32 = SQLITE_OK
            
            switch values[index] {
            case .text(let value):
                result = sqlite3_bind_text(statementID, sqlIndex, value, -1, SQLITE_TRANSIENT)
            case .int(let value):
                result = sqlite3_bind_int64(statementID, sqlIndex, Int64(value))
            case .double(let value):
                result = sqlite3_bind_double(statementID, sqlIndex, value)
            case .blob(let value):
                _ = value.withUnsafeBytes { (bytes) -> Bool in
                    let rawPointer = bytes.baseAddress
                    result = sqlite3_bind_blob(statementID, sqlIndex, rawPointer, Int32(value.count), SQLITE_TRANSIENT)
                    return true
                }
            case .null:
                result = sqlite3_bind_null(statementID, sqlIndex)
            }
            
            guard result == SQLITE_OK else {
                throw SQLError.failedToBindValueToStatement(code: result, message: errorMessage?.current ?? "Failed to bind value to statement.")
            }
        }
    }
    
    @discardableResult
    public func step() throws -> StepResult {
        let result = sqlite3_step(statementID)
        switch result {
        case SQLITE_DONE:
            return .done
        case SQLITE_ROW:
            return .row(try fetchCurrentRow())
        default:
            throw SQLError.failedToStepStatement(code: result, message: errorMessage?.current ?? "Failed to step statement.")
        }
    }
    
    public func stepAllRows() throws -> [SQLRow] {
        var rows = [SQLRow]()
        
        loop: while true {
            switch try step() {
            case .done:
                break loop
            case .row(let row):
                rows.append(row)
            }
        }
        
        return rows
    }
    
    public func reset() throws {
        let result = sqlite3_reset(statementID)
        guard result == SQLITE_OK else {
            throw SQLError.failedToResetStatement(code: result, message: errorMessage?.current ?? "Failed to reset statement.")
        }
    }
    
    // MARK: - Convenience
    
    
    @discardableResult
    public func resetBindAndStep(values: SQLValue...) throws -> StepResult {
        return try resetBindAndStep(values: values)
    }
    
    @discardableResult
    public func resetBindAndStep(values: [SQLValue]) throws -> StepResult {
        try reset()
        try bind(values: values)
        return try step()
    }

    public func resetBindAndStepAllRows(values: SQLValue...) throws -> [SQLRow] {
        return try resetBindAndStepAllRows(values: values)
    }

    public func resetBindAndStepAllRows(values: [SQLValue]) throws -> [SQLRow] {
        try reset()
        try bind(values: values)
        return try stepAllRows()
    }
    
    // MARK: - Helpers
    
    private func fetchCurrentRow() throws -> SQLRow {
        
        let columnCount = sqlite3_column_count(statementID)
        guard columnCount > 0 else {
            return SQLRow()
        }
        
        var row = SQLRow()
        
        for columnIndex in 0..<columnCount {
            let columnType = sqlite3_column_type(statementID, columnIndex)
            let value: SQLValue
            
            switch columnType {
            case SQLITE_INTEGER:
                value = .int(Int(sqlite3_column_int64(statementID, columnIndex)))
            case SQLITE_FLOAT:
                value = .double(sqlite3_column_double(statementID, columnIndex))
            case SQLITE_TEXT:
                if let text = sqlite3_column_text(statementID, columnIndex) {
                    value = .text(String(cString: text))
                } else {
                    value = .null
                }
            case SQLITE_BLOB:
                if let blob = sqlite3_column_blob(statementID, columnIndex) {
                    let byteCount = sqlite3_column_bytes(statementID, columnIndex)
                    if byteCount > 0 {
                        value = .blob(Data(bytes: blob, count: Int(byteCount)))
                    } else {
                        value = .null
                    }
                } else {
                    value = .null
                }
            case SQLITE_NULL:
                value = .null
            default:
                value = .null
            }
            
            let columnName: SQLColumnName
            if let rawColumnName = sqlite3_column_name(statementID, columnIndex) {
                columnName = String(cString: rawColumnName)
            } else {
                columnName = "Column \(columnIndex)"
            }
            
            row.addColumn(name: columnName, index: columnIndex, value: value)
        }
        
        return row
    }
}
