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
                t.column("shell", .text).notNull().defaults(to: "zsh")
            }
        }
    }

    // MARK: - Command Functions (Placeholders)

    func fetchCommands() -> [Command] {
        // Placeholder: Implement fetching commands from the database.
        return []
    }

    func addCommand(_ command: Command) {
        // Placeholder: Implement adding a new command to the database.
    }

    func deleteCommand(_ command: Command) {
        // Placeholder: Implement deleting a command from the database.
    }

    // MARK: - Settings Functions (Placeholders)

    func fetchSettings() -> AppSettings {
        // Placeholder: Implement fetching settings from the database.
        return AppSettings(shell: "zsh")
    }

    func saveSettings(_ settings: AppSettings) {
        // Placeholder: Implement saving settings to the database.
    }
}
