//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation

public enum SQLValue {
    case text(String)
    case int(Int)
    case double(Double)
    case blob(Data)
    case null
}
