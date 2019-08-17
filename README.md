# SQLiteKit

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/) ![MIT License](https://img.shields.io/badge/license-MIT-blue.svg) ![language Swift 5.1](https://img.shields.io/badge/language-Swift%205.1-orange.svg) ![platform macOS](https://img.shields.io/badge/platform-macOS-lightgrey.svg)

Simple Swift wrapper for accessing a `.sqlite3` database in a thread safe manner. 

## License

SQLiteKit is released under the MIT license. See `LICENSE` file for more detailed information.

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
If you are using Xcode 11 or newer, you can add SQLiteKit by entering the URL to the
repository via the `File` menu:

```
File > Swift Packages > Add Package Dependency...
```

**Note:** SQLiteKit requires **Swift 5.1** or later.

# Reference Documentation

There is generated [reference documentation](https://apparata.github.io/SQLiteKit/SQLiteKit/)
available.

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
