import Foundation
import GRDB

// The AppSettings model.
struct AppSettings: Codable, Equatable {
    var id: Int64?
    var shell: String
}

// Add GRDB conformance.
extension AppSettings: FetchableRecord, MutablePersistableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
