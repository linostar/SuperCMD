import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var settings: AppSettings = AppSettings(shell: "zsh")
    
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
            }
            
            Spacer()
            
            HStack {
                Button("Cancel", role: .cancel, action: { dismiss() })
                Spacer()
                Button("Save", action: saveAndDismiss)
            }
        }
        .padding()
        .frame(width: 400, height: 200) // Reduced height
        .onAppear(perform: loadSettings)
    }

    private func loadSettings() {
        settings = dataManager.fetchSettings()
    }

    private func saveAndDismiss() {
        dataManager.saveSettings(settings)
        dismiss()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(DataManager.shared)
    }
}
