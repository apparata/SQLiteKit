//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation

public typealias SQLViewName = String

// MARK: - SQLView

public struct SQLView {
                
    public let name: SQLViewName
    public let columns: [SQLTableColumn]
    public let selectStatement: String
    public private(set) var schemaName: String?
    
    init(_ name: SQLTableName, as selectStatement: String, @SQLTableBuilder columns: () -> [SQLTableColumn]) {
        self.name = name
        self.columns = columns()
        self.selectStatement = selectStatement
    }

    init(_ name: SQLTableName, as selectStatement: String) {
        self.name = name
        self.columns = []
        self.selectStatement = selectStatement
    }
    
    public func schema(_ name: String) -> SQLView {
        replacing(\.schemaName, with: name)
    }
}

// MARK: - Extensions

extension SQLView: KeyPathReplaceable { }
