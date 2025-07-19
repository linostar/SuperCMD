import Foundation
import GRDB

// DataManager is a singleton class that manages the database.
class DataManager: ObservableObject {
    // The shared instance of the data manager.
    static let shared = DataManager()

    // The database queue for writing and reading data.
    private var dbQueue: DatabaseQueue

    private init() {
        do {
            // Create a folder in the Application Support directory for the app's data.
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let appDirectoryURL = appSupportURL.appendingPathComponent("SuperCMD")
            try fileManager.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            
            // Create the database file in the app's directory.
            let dbURL = appDirectoryURL.appendingPathComponent("supercmd.sqlite")
            dbQueue = try DatabaseQueue(path: dbURL.path)
            
            // Create the necessary tables in the database.
            try createTables()
        } catch {
            // If there is an error, terminate the app.
            fatalError("Failed to initialize database: \(error)")
        }
    }

    // Create the tables for the commands and settings.
    private func createTables() throws {
        try dbQueue.write { db in
            try db.create(table: "command", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("shell", .text).notNull()
                t.column("command", .text).notNull()
            }
            
            try db.create(table: "appSettings", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("shell", .text).notNull()
            }
            
            // Ensure there's a default settings row
            if try AppSettings.fetchCount(db) == 0 {
                var defaultSettings = AppSettings(id: 1, shell: "zsh")
                try defaultSettings.insert(db)
            }
        }
    }

    // MARK: - Command Functions

    func fetchCommands() -> [Command] {
        do {
            return try dbQueue.read { db in
                try Command.fetchAll(db)
            }
        } catch {
            print("Failed to fetch commands: \(error)")
            return []
        }
    }

    func addCommand(_ command: Command) {
        do {
            try dbQueue.write { db in
                var newCommand = command
                try newCommand.insert(db)
            }
        } catch {
            print("Failed to add command: \(error)")
        }
    }

    func deleteCommand(id: Int64) {
        do {
            _ = try dbQueue.write { db in
                try Command.deleteOne(db, key: id)
            }
        } catch {
            print("Failed to delete command: \(error)")
        }
    }

    // MARK: - Settings Functions

    func fetchSettings() -> AppSettings {
        do {
            return try dbQueue.read { db in
                // There should always be exactly one settings row
                try AppSettings.fetchOne(db) ?? AppSettings(id: 1, shell: "zsh")
            }
        } catch {
            print("Failed to fetch settings: \(error)")
            return AppSettings(id: 1, shell: "zsh")
        }
    }

    func saveSettings(_ settings: AppSettings) {
        do {
            try dbQueue.write { db in
                var mutableSettings = settings
                try mutableSettings.save(db)
            }
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}
