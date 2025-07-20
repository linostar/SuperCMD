import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var settings: AppSettings = AppSettings(shell: "zsh")
    
    private let availableShells = ["zsh", "bash", "sh"]

    var body: some View {
        VStack {
            HStack {
                Text("General Settings").foregroundColor(.black).font(.headline)
                Spacer()
            }
            Form {
                Picker("Default Shell:", selection: $settings.shell) {
                    ForEach(availableShells, id: \.self) { shell in
                        Text(shell).tag(shell)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .background(Color.clear)
                .foregroundColor(.black)
                .padding(.top, 8)
            }
            .background(Color.clear)

            Spacer()
            
            HStack {
                Button("Cancel", role: .cancel, action: { dismiss() })
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                Spacer()
                Button("Save", action: saveAndDismiss)
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth: 1)
                    )
            }
        }
        .padding()
        .frame(width: 400, height: 200) // Reduced height
        .onAppear(perform: loadSettings)
        .background(WindowAccessor(callback: { window in
            window?.level = .floating
        }))
        .background(Color.clear)
        .foregroundColor(.black.opacity(0.7))
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

struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.callback(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            self.callback(nsView.window)
        }
    }
}
