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
                .foregroundColor(.terminalGreen)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.terminalGreen, lineWidth: 1)
                )
                Button(action: {
                    confirmingDeleteCommandId = nil // Reset confirmation on any action
                    openSettings()
                }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.terminalGreen)
                .padding(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.terminalGreen, lineWidth: 1)
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
                                    .stroke(Color.terminalGreen, lineWidth: 1)
                            )
                        
                        Text("Command")
                            .font(.caption)
                        TextField("", text: $newCommandString)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(4)
                            .background(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.terminalGreen, lineWidth: 1)
                            )
                            .padding(.bottom, 8)
                    }
                    HStack {
                        Spacer()
                        Button("Cancel", role: .cancel) {
                            showingAddCommandForm = false
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.terminalGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.terminalGreen, lineWidth: 1)
                        )

                        Button("Add", action: addCommand)
                            .disabled(newCommandName.isEmpty || newCommandString.isEmpty)
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(.terminalGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.terminalGreen, lineWidth: 1)
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
                            .foregroundColor(.terminalGreen)
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
                    .foregroundColor(.terminalGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.terminalGreen, lineWidth: 1)
                    )
                Spacer()
            }.padding()

        }
        .foregroundColor(.terminalGreen)
        .background(Color.panelBackground.edgesIgnoringSafeArea(.all))
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

// Fixed colors so the look doesn't depend on the SDK: system colors and translucent
// backgrounds render darker / as glass when built with the macOS 26+ SDK.
extension Color {
    static let terminalGreen = Color(red: 0x25 / 255, green: 0xC6 / 255, blue: 0x5F / 255)
    static let panelBackground = Color(red: 0x37 / 255, green: 0x38 / 255, blue: 0x3B / 255)
}
