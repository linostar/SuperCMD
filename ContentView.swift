import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.openSettings) private var openSettings
    @State private var commands: [Command] = []
    
    // State for the new command form
    @State private var showingAddCommandForm = false
    @State private var newCommandName = ""
    @State private var newCommandString = ""
    @State private var settings: AppSettings = AppSettings(shell: "zsh")


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("SuperCMD")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddCommandForm.toggle() }) {
                    Image(systemName: "plus")
                }
                Button(action: { openSettings() }) {
                    Image(systemName: "gear")
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            // Add Command Form
            if showingAddCommandForm {
                VStack {
                    Form {
                        TextField("Command Name", text: $newCommandName)
                        TextField("Command", text: $newCommandString)
                    }
                    HStack {
                        Spacer()
                        Button("Cancel", role: .cancel) {
                            showingAddCommandForm = false
                        }
                        Button("Add", action: addCommand)
                            .disabled(newCommandName.isEmpty || newCommandString.isEmpty)
                    }
                }
                .padding()
            }

            Divider()

            // Command List
            List {
                if commands.isEmpty {
                    Text("No commands yet. Add one using the '+' button.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(commands) { command in
                        CommandRowView(command: command, onCommandDeleted: loadData)
                    }
                }
            }
            .onAppear(perform: loadData)
            
            Divider()
            
            // Footer
            HStack {
                Button("Quit", action: { NSApplication.shared.terminate(nil) })
                Spacer()
            }.padding()

        }
        .frame(width: 320, height: 450)
    }

    private func loadData() {
        commands = dataManager.fetchCommands()
        settings = dataManager.fetchSettings()
    }
    
    private func addCommand() {
        let newCommand = Command(name: newCommandName, shell: settings.shell, command: newCommandString)
        dataManager.addCommand(newCommand)
        
        // Reset form and hide it
        newCommandName = ""
        newCommandString = ""
        showingAddCommandForm = false
        
        // Refresh command list
        loadData()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DataManager.shared)
    }
}
