//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation

public struct SQLRow {
    
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
    
    public subscript(_ index: Int) -> SQLValue {
        return columns[index]
    }
    
    public subscript(_ columnName: SQLColumnName) -> SQLValue? {
        if let index = columnsByName[columnName],
            Int(index) < columns.count {
            return columns[Int(index)]
        } else {
            return nil
        }
    }
    
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
