//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation
import libsqlite3

internal typealias SQLDatabaseID = OpaquePointer
internal typealias SQLStatementID = OpaquePointer

internal protocol SQLErrorMessage: AnyObject {
    var current: String { get }
}

internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)

internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
