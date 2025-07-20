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
                    Text("Add command")
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.green)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.green, lineWidth: 1)
                )
                Button(action: {
                    confirmingDeleteCommandId = nil // Reset confirmation on any action
                    openSettings()
                }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.green)
                .padding(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.green, lineWidth: 1)
                )
            }
            .padding()

            // Add Command Form
            if showingAddCommandForm {
                VStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Command name")
                            .font(.caption)
                        TextField("", text: $newCommandName)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(4)
                            .background(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                        
                        Text("Command")
                            .font(.caption)
                        TextField("", text: $newCommandString)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(4)
                            .background(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                            .padding(.bottom, 8)
                    }
                    HStack {
                        Spacer()
                        Button("Cancel", role: .cancel) {
                            showingAddCommandForm = false
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.green, lineWidth: 1)
                        )

                        Button("Add", action: addCommand)
                            .disabled(newCommandName.isEmpty || newCommandString.isEmpty)
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                    }
                }
                .padding()
            }

            // Command List
            ScrollView {
                VStack(spacing: 10) {
                    if commands.isEmpty {
                        Text("No commands yet. Add one using the 'Add command' button.")
                            .foregroundColor(.green)
                            .padding()
                    } else {
                        ForEach(commands) { command in
                            CommandRowView(
                                command: command,
                                settings: settings,
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
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.green, lineWidth: 1)
                    )
                Spacer()
            }.padding()

        }
        .foregroundColor(.green)
        .background(Color.black.opacity(0.7).edgesIgnoringSafeArea(.all))
        .frame(minWidth: 540, minHeight: 520)
        .onTapGesture {
            confirmingDeleteCommandId = nil
        }
    }

    private func loadData() {
        commands = dataManager.fetchCommands()
        settings = dataManager.fetchSettings()
    }
    
    private func addCommand() {
        let newCommand = Command(name: newCommandName, command: newCommandString)
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
