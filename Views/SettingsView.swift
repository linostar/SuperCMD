import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var settings: AppSettings = AppSettings(shell: "zsh")
    @State private var newCommandName = ""
    @State private var newCommandString = ""
    
    private let availableShells = ["zsh", "bash", "sh"]

    var body: some View {
        VStack {
            Form {
                Section(header: Text("General Settings")) {
                    Picker("Default Shell:", selection: $settings.shell) {
                        ForEach(availableShells, id: \.self) { shell in
                            Text(shell).tag(shell)
                        }
                    }
                }

                Section(header: Text("Add New Command")) {
                    TextField("Command Name", text: $newCommandName)
                    TextField("Command", text: $newCommandString)
                    HStack {
                        Spacer()
                        Button("Add Command", action: addCommand)
                            .disabled(newCommandName.isEmpty || newCommandString.isEmpty)
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Button("Cancel", role: .cancel, action: { dismiss() })
                Spacer()
                Button("Save", action: saveAndDismiss)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
        .onAppear(perform: loadSettings)
    }

    private func loadSettings() {
        settings = dataManager.fetchSettings()
    }

    private func saveAndDismiss() {
        dataManager.saveSettings(settings)
        dismiss()
    }
    
    private func addCommand() {
        let newCommand = Command(name: newCommandName, shell: settings.shell, command: newCommandString)
        dataManager.addCommand(newCommand)
        // In a real app, you would update the commands list here or via a binding.
        newCommandName = ""
        newCommandString = ""
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(DataManager.shared)
    }
}
