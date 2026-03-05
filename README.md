# SQLiteKit

A simple, thread-safe Swift wrapper for accessing SQLite databases.

## Features

- 🔒 **Thread-Safe**: All database access is serialized through a dedicated dispatch queue
- 🎯 **Type-Safe**: Swift-based type system for values and columns
- ✨ **Declarative API**: Build table schemas using a result builder DSL
- ⚡ **Prepared Statements**: Efficient execution of repeated queries
- 💾 **Transaction Support**: Full ACID transaction support
- 📦 **Backup/Restore**: Easy database backup and restoration
- 📱 **Cross-Platform**: Supports macOS, iOS, tvOS, and visionOS
- 📖 **Comprehensive Documentation**: Full DocC documentation included

## Quick Start

### Opening a Database

```swift
import SQLiteKit

let dbQueue = try SQLQueue.open(path: "/path/to/database.sqlite3")
```

### Creating a Table

```swift
try dbQueue.runSynchronously { db in
    try db.execute(sql: """
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT UNIQUE,
            age INTEGER
        )
    """)
}
```

### Inserting Data

```swift
dbQueue.run { db in
    try db.execute(
        sql: "INSERT INTO users (name, email, age) VALUES (?, ?, ?)",
        values: .text("Alice"), .text("alice@example.com"), .int(30)
    )
}
```

### Querying Data

```swift
try dbQueue.runSynchronously { db in
    let statement = try db.prepare(statement: "SELECT name, email, age FROM users WHERE age > ?")
    try statement.bind(values: .int(18))

    let rows = try statement.stepAllRows()
    for row in rows {
        let name: String? = row.value(name: "name")
        let email: String? = row.value(name: "email")
        let age: Int? = row.value(name: "age")
        print("\(name ?? "Unknown") (\(email ?? "no email")): \(age ?? 0) years old")
    }
}
```

## Advanced Usage

### Prepared Statements

Prepared statements are efficient when executing the same query multiple times:

```swift
try dbQueue.runSynchronously { db in
    let statement = try db.prepare(statement: "INSERT INTO users (name, email, age) VALUES (?, ?, ?)")

    try statement.resetBindAndStep(values: .text("Bob"), .text("bob@example.com"), .int(25))
    try statement.resetBindAndStep(values: .text("Charlie"), .text("charlie@example.com"), .int(35))
    try statement.resetBindAndStep(values: .text("Diana"), .text("diana@example.com"), .int(28))
}
```

### Transactions

Ensure atomic operations with transactions:

```swift
dbQueue.transaction { db in
    try db.execute(sql: "UPDATE accounts SET balance = balance - 100 WHERE id = 1")
    try db.execute(sql: "UPDATE accounts SET balance = balance + 100 WHERE id = 2")

    // Return .commit to save changes, or .rollback to discard them
    return .commit
}
```

### Declarative Table Definitions

Define tables using a type-safe DSL:

```swift
let users = SQLTable("users") {
    SQLColumn("id", Int.self).notNull()
    SQLColumn("name", String.self).notNull()
    SQLColumn("email", String.self).notNull()
    SQLColumn("age", Int.self)
    SQLColumn("created_at", Int.self).defaultTo(SQLExpression("CURRENT_TIMESTAMP"))
}
.primaryKey("id")
.unique("email")

try dbQueue.runSynchronously { db in
    try db.createTable(users)
}
```

### Observing Changes

Monitor database changes in real-time:

```swift
dbQueue.didUpdate = { type, table, rowID in
    print("Update: \(type) on table \(table ?? "unknown") at row \(rowID)")
}
```

### Backup and Restore

Create and restore database backups:

```swift
// Create a backup
try dbQueue.storeBackupSynchronously(to: "/path/to/backup.sqlite3")

// Restore from backup
try dbQueue.restoreBackupSynchronously(from: "/path/to/backup.sqlite3")

// Use vacuum for smaller backup files (slower)
try dbQueue.storeBackupSynchronously(to: "/path/to/backup.sqlite3", vacuum: true)
```

## Complete Example

```swift
import Foundation
import SQLiteKit

let databasePath = "/tmp/testdb.sqlite3"

do {
    let dbQueue = try SQLQueue.open(path: databasePath)

    // Observe database changes
    dbQueue.didUpdate = { type, table, rowID in
        print("Did \(type) table \(table ?? "") rowID \(rowID)")
    }

    // Create table
    try dbQueue.runSynchronously { db in
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS Car (
                carID INTEGER PRIMARY KEY ASC,
                make TEXT NOT NULL,
                color TEXT NOT NULL
            )
        """)
    }

    // Prepare statement
    var insertCar: SQLStatement?
    try dbQueue.runSynchronously { db in
        insertCar = try db.prepare(statement: "INSERT INTO Car (make, color) VALUES (?, ?)")
    }

    // Insert data in a transaction
    dbQueue.transaction { db in
        try insertCar?.resetBindAndStep(values: .text("Ford"), .text("Red"))
        try insertCar?.resetBindAndStep(values: .text("Ferrari"), .text("Green"))
        try insertCar?.resetBindAndStep(values: .text("Volvo"), .text("Blue"))
        return .commit
    }

    // Query data
    try dbQueue.runSynchronously { db in
        let statement = try db.prepare(statement: "SELECT make, color FROM Car")
        let rows = try statement.stepAllRows()

        for row in rows {
            let make: String? = row.value(name: "make")
            let color: String? = row.value(name: "color")
            print("Car: \(make ?? "unknown") - \(color ?? "unknown")")
        }
    }

} catch {
    print("Error: \(error)")
    exit(1)
}
```

## API Overview

### Core Classes

- **`SQLQueue`** - Thread-safe database wrapper for asynchronous and synchronous operations
- **`SQLDatabase`** - Protocol defining the database interface
- **`SQLStatement`** - Prepared statement for efficient query execution
- **`SQLValue`** - Enum representing SQLite values (text, int, double, blob, null)
- **`SQLRow`** - Row data with type-safe value extraction
- **`SQLError`** - Comprehensive error types

### Query Builder

- **`SQLQuery`** - SQL query representation
- **`SQLTable`** - Declarative table definition
- **`SQLColumn`** - Type-safe column definition with constraints

## Documentation

Full API documentation is available in DocC format. To view:

1. Open the package in Xcode
2. Build documentation: Product → Build Documentation (⌃⌘D)
3. View in Xcode's documentation viewer

Or generate static documentation:

```bash
xcodebuild docbuild -scheme SQLiteKit -destination 'platform=macOS'
```

## License

SQLiteKit is licensed under the [0BSD License](LICENSE). This is a "zero-clause" BSD license that allows you to use, modify, and distribute the code without any restrictions.
