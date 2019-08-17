import XCTest
@testable import SQLiteKit

final class SQLiteKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SQLiteKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
