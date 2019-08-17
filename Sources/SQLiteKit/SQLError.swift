//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation

public typealias SQLErrorCode = Int32

public enum SQLError: Error {
    case failedToOpenDatabase(code: SQLErrorCode, message: String)
    case failedToPrepareStatement(code: SQLErrorCode, message: String)
    case failedToStepStatement(code: SQLErrorCode, message: String)
    case failedToBindValueToStatement(code: SQLErrorCode, message: String)
    case failedToResetStatement(code: SQLErrorCode, message: String)
    case failedToExecute(code: SQLErrorCode, message: String)
}
