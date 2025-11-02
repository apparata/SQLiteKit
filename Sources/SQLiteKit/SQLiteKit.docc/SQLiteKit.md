# ``SQLiteKit``

A simple, thread-safe Swift wrapper for SQLite databases.

## Overview

SQLiteKit provides a straightforward interface for working with SQLite databases in Swift. It offers:

- **Thread Safety**: All database access is serialized through a dedicated queue
- **Type Safety**: Swift-based type system for values and columns
- **Declarative API**: Build table schemas using a result builder DSL
- **Prepared Statements**: Efficient execution of repeated queries
- **Transaction Support**: Full ACID transaction support
- **Backup/Restore**: Easy database backup and restoration

## Getting Started

### Installation

Add SQLiteKit to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/apparata/SQLiteKit.git", from: "1.0.0")
]
```

### Basic Usage

```swift
import SQLiteKit

// Open a database
let dbQueue = try SQLQueue.open(path: "/path/to/database.sqlite3")

// Execute queries synchronously
try dbQueue.runSynchronously { db in
    try db.execute(sql: """
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            age INTEGER
        )
    """)
}

// Insert data asynchronously
dbQueue.run { db in
    try db.execute(
        sql: "INSERT INTO users (name, age) VALUES (?, ?)",
        values: .text("Alice"), .int(30)
    )
}
```

### Using Prepared Statements

```swift
try dbQueue.runSynchronously { db in
    let statement = try db.prepare(statement: "INSERT INTO users (name, age) VALUES (?, ?)")

    // Execute multiple times with different values
    try statement.resetBindAndStep(values: .text("Bob"), .int(25))
    try statement.resetBindAndStep(values: .text("Charlie"), .int(35))
}
```

### Querying Data

```swift
try dbQueue.runSynchronously { db in
    let statement = try db.prepare(statement: "SELECT name, age FROM users WHERE age > ?")
    try statement.bind(values: .int(20))

    let rows = try statement.stepAllRows()
    for row in rows {
        let name: String? = row.value(name: "name")
        let age: Int? = row.value(name: "age")
        print("\(name ?? "unknown"): \(age ?? 0)")
    }
}
```

### Using Transactions

```swift
dbQueue.transaction { db in
    try db.execute(sql: "UPDATE accounts SET balance = balance - 100 WHERE id = 1")
    try db.execute(sql: "UPDATE accounts SET balance = balance + 100 WHERE id = 2")
    return .commit
}
```

### Declarative Table Definitions

```swift
let users = SQLTable("users") {
    SQLColumn("id", Int.self).notNull()
    SQLColumn("name", String.self).notNull()
    SQLColumn("email", String.self)
    SQLColumn("age", Int.self)
}
.primaryKey("id")
.unique("email")

try dbQueue.runSynchronously { db in
    try db.createTable(users)
}
```

## Topics

### Essentials

- ``SQLQueue``
- ``SQLDatabase``
- ``SQLStatement``

### Data Types

- ``SQLValue``
- ``SQLRow``
- ``SQLError``

### Query Building

- ``SQLQuery``
- ``SQLTable``
- ``SQLColumn``

### Supporting Types

- ``SQLUpdateType``
- ``SQLTransactionResult``

## License

SQLiteKit is licensed under 0BSD. See LICENSE file for details.
