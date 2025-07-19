import SwiftUI

struct CommandRowView: View {
    @EnvironmentObject private var dataManager: DataManager
    let command: Command
    let onCommandDeleted: () -> Void // Callback to refresh the list

    @State private var output: String = ""
    @State private var isRunning: Bool = false
    @State private var showingOutput: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text(command.name)
                        .font(.headline)
                    Text(command.command)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Delete Button
                Button(role: .destructive, action: deleteCommand) {
                    Image(systemName: "trash")
                }
                
                // Run Button
                Button(action: {
                    showingOutput.toggle()
                    if showingOutput {
                        runCommand()
                    }
                }) {
                    Image(systemName: showingOutput ? "chevron.down.circle.fill" : "play.fill")
                }
                .disabled(isRunning)
            }
            
            // Output Area
            if showingOutput {
                if isRunning {
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.vertical, 5)
                }
                
                if !output.isEmpty {
                    ScrollView {
                        Text(output)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                    .padding(8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func deleteCommand() {
        guard let commandId = command.id else { return }
        dataManager.deleteCommand(id: commandId)
        onCommandDeleted() // Trigger the callback
    }

    private func runCommand() {
        isRunning = true
        output = ""
        
        let process = Process()
        let outputPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/bin/\(command.shell)")
        process.arguments = ["-c", command.command]
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        // Asynchronously read the output
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if let newOutput = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.output += newOutput
                }
            }
        }

        // Process termination handler
        process.terminationHandler = { _ in
            DispatchQueue.main.async {
                self.isRunning = false
                // Ensure all output is read
                outputPipe.fileHandleForReading.readabilityHandler = nil
            }
        }

        do {
            try process.run()
        } catch {
            self.output = "Failed to run command: \(error.localizedDescription)"
            self.isRunning = false
        }
    }
}

struct CommandRowView_Previews: PreviewProvider {
    static var previews: some View {
        CommandRowView(command: Command(id: 1, name: "List Files", shell: "zsh", command: "ls -l"), onCommandDeleted: {})
            .environmentObject(DataManager.shared)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
