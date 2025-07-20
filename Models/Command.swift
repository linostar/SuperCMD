import Foundation
import GRDB

// The Command model, conforming to Codable and Identifiable for use with SwiftUI.
struct Command: Codable, Identifiable, Equatable {
    var id: Int64?
    var name: String
    var command: String
}

// Add GRDB conformance for database operations.
extension Command: FetchableRecord, MutablePersistableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
