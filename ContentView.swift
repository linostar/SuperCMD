import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.openSettings) private var openSettings
    @State private var commands: [Command] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("SuperCMD")
                    .font(.headline)
                Spacer()
                Button(action: {
                    openSettings()
                }) {
                    Image(systemName: "gear")
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Command List
            List {
                if commands.isEmpty {
                    Text("No commands yet. Add one from the settings.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(commands) { command in
                        CommandRowView(command: command)
                    }
                }
            }
            .onAppear(perform: loadCommands)
            
            Divider()
            
            // Footer
            HStack {
                Button("Quit", action: { NSApplication.shared.terminate(nil) })
                Spacer()
            }.padding()

        }
        .frame(width: 300, height: 400)
    }

    private func loadCommands() {
        commands = dataManager.fetchCommands()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DataManager.shared)
    }
}
