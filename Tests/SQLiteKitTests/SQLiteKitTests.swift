import XCTest
@testable import SQLiteKit

final class SQLiteKitTests: XCTestCase {
    
    func testTableBuilder() {

        let table = SQLTable("CountryValues") {
            SQLColumn("countryID", String.self).notNull()
            SQLColumn("categoryID", Int.self).notNull()
            SQLColumn("year", Int.self).notNull()
            SQLColumn("value", Double.self).notNull()
        }
        .primaryKey("countryID", "categoryID", "year", onConflict: .replace)

        let query: SQLQuery = SQLQuery.createTable(table)
        
        print(query.string)
    }

    func testViewBuilder() {
        let view = SQLView("MyView", as: "SELECT countryID, year FROM CountryValues") {
            SQLColumn("myCountryID", String.self).notNull()
            SQLColumn("myYear", Int.self).notNull()
        }

        let query: SQLQuery = SQLQuery.createView(view)
        
        print(query.string)
    }

    func testViewBuilderWithoutColumns() {
        let view = SQLView("MyView", as: "SELECT countryID, year FROM CountryValues")

        let query: SQLQuery = SQLQuery.createView(view)
        
        print(query.string)
    }    
}
