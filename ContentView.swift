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
    
    // State to track which command is awaiting delete confirmation
    @State private var confirmingDeleteCommandId: Int64? = nil


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("SuperCMD")
                    .font(.headline)
                Spacer()
                Button(action: {
                    confirmingDeleteCommandId = nil // Reset confirmation on any action
                    showingAddCommandForm.toggle()
                }) {
                    Image(systemName: "plus")
                }
                Button(action: {
                    confirmingDeleteCommandId = nil // Reset confirmation on any action
                    openSettings()
                }) {
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

            // Command List
            ScrollView {
                VStack(spacing: 10) {
                    if commands.isEmpty {
                        Text("No commands yet. Add one using the '+' button.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(commands) { command in
                            CommandRowView(
                                command: command,
                                confirmingDeleteCommandId: $confirmingDeleteCommandId,
                                onCommandChanged: loadData
                            )
                        }
                    }
                }.padding(.horizontal).padding(.top, 8)
            }
            .onAppear(perform: loadData)
            
            // Error Banner
            if let errorMessage = dataManager.latestError {
                HStack {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding(8)
                    Spacer()
                    Button(action: { dataManager.latestError = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                .background(Color.red)
                .padding()
            }
            
            // Footer
            HStack {
                Button("Quit", action: { NSApplication.shared.terminate(nil) })
                Spacer()
            }.padding()

        }
        .frame(minWidth: 540, minHeight: 500)
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
