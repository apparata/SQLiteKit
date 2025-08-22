# SQLiteKit

Simple Swift wrapper for accessing a `.sqlite3` database in a thread safe manner. 

## License

SQLiteKit is licensed under 0BSD. See LICENSE file for details.

# Table of Contents

- [Getting Started](#getting-started)
- [Reference Documentation](#reference-documentation)
- [Example](#example)

# Getting Started

Add SQLiteKit to your Swift package by adding the following to your `Package.swift` file in
the dependencies array:

```swift
.package(url: "https://github.com/apparata/SQLiteKit.git", from: "<version>")
```

## Example

```swift
import Foundation
import SQLiteKit

let databasePath = "/tmp/testdb.sqlite3"

do {
    let dbQueue = try SQLQueue.open(path: databasePath)
    
    dbQueue.didUpdate = { type, table, rowID in
        print("Did \(type) table \(table ?? "") rowID \(rowID)")
    }
    
    try dbQueue.runSynchronously { db in
        try db.execute(sql: "CREATE TABLE IF NOT EXISTS Car (carID INTEGER PRIMARY KEY ASC, make TEXT NOT NULL, color TEXT NOT NULL);")
    }

    var insertCar: SQLStatement?
    
    try dbQueue.runSynchronously { db in
        insertCar = try db.prepare(statement: "INSERT INTO Car (make, color) VALUES (?, ?);")
    }
    
    dbQueue.transaction { db in
        
        try insertCar?.resetBindAndStep(values: .text("Ford"), .text("Red"))
        try insertCar?.resetBindAndStep(values: .text("Ferrari"), .text("Green"))
        try insertCar?.resetBindAndStep(values: .text("Volvo"), .text("Blue"))

        return .commit
    }
    
    RunLoop.main.run(until: Date().addingTimeInterval(2))
    
} catch {
    dump(error)
    exit(1)
}
```

## Declarative Table Query Example

```
let table = SQLTable("Cars") {
    SQLColumn("brand", String.self).notNull()
    SQLColumn("model", Int.self).notNull()
    SQLColumn("doorCount", Int.self).notNull()
    SQLColumn("weight", Double.self).notNull()
}
.primaryKey("brand", "model", onConflict: .replace)

let query: SQLQuery = SQLQuery.createTable(table)

print(query.string)
```
