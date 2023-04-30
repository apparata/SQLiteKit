import Foundation

public enum SQLValue {
    case text(String)
    case int(Int)
    case double(Double)
    case blob(Data)
    case null
}
