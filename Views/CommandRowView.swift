import SwiftUI

struct CommandRowView: View {
    @EnvironmentObject private var dataManager: DataManager
    let command: Command
    @Binding var confirmingDeleteCommandId: Int64?
    let onCommandChanged: () -> Void // Unified callback for delete/edit

    @State private var output: String = ""
    @State private var isRunning: Bool = false
    @State private var showingOutput: Bool = false
    
    // State for the inline edit form
    @State private var showingEditForm = false
    @State private var editedName: String
    @State private var editedCommand: String
    
    private var isConfirmingDelete: Bool {
        confirmingDeleteCommandId == command.id
    }

    init(command: Command, confirmingDeleteCommandId: Binding<Int64?>, onCommandChanged: @escaping () -> Void) {
        self.command = command
        self._confirmingDeleteCommandId = confirmingDeleteCommandId
        self.onCommandChanged = onCommandChanged
        _editedName = State(initialValue: command.name)
        _editedCommand = State(initialValue: command.command)
    }

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
                
                // Edit Button
                Button(action: {
                    confirmingDeleteCommandId = nil // Reset confirmation on any action
                    showingEditForm.toggle()
                }) {
                    Image(systemName: "pencil")
                }

                // Delete Button
                Button(role: .destructive, action: handleDeleteTap) {
                    Image(systemName: "trash")
                }
                .background(isConfirmingDelete ? Color.black.opacity(0.18) : Color.clear)
                .cornerRadius(4)
                
                // Run Button
                Button(action: {
                    confirmingDeleteCommandId = nil // Reset confirmation on any action
                    showingOutput.toggle()
                    if showingOutput {
                        runCommand()
                    }
                }) {
                    Image(systemName: showingOutput ? "chevron.down.circle.fill" : "play.fill")
                }
                .disabled(isRunning)
            }
            
            // Inline Edit Form
            if showingEditForm {
                VStack {
                    Form {
                        TextField("Name", text: $editedName)
                        TextField("Command", text: $editedCommand)
                    }
                    HStack {
                        Spacer()
                        Button("Cancel", role: .cancel) {
                            // Reset state and hide form
                            editedName = command.name
                            editedCommand = command.command
                            showingEditForm = false
                        }
                        Button("Save", action: updateCommand)
                    }
                }
                .padding(.top, 8)
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.01))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.top, 4)
    }

    private func handleDeleteTap() {
        if isConfirmingDelete {
            // This is the second click, perform deletion
            guard let commandId = command.id else { return }
            dataManager.deleteCommand(id: commandId)
            onCommandChanged()
        } else {
            // This is the first click, set for confirmation
            confirmingDeleteCommandId = command.id
        }
    }
    
    private func updateCommand() {
        var updatedCommand = command
        updatedCommand.name = editedName
        updatedCommand.command = editedCommand
        dataManager.updateCommand(updatedCommand)
        showingEditForm = false
        onCommandChanged() // Trigger the callback to refresh the list
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
            let errorMessage = "Failed to run command: \(error.localizedDescription)"
            DispatchQueue.main.async {
                self.dataManager.latestError = errorMessage
                self.output = errorMessage
            }
            self.isRunning = false
        }
    }
}

struct CommandRowView_Previews: PreviewProvider {
    static var previews: some View {
        CommandRowView(
            command: Command(id: 1, name: "List Files", shell: "zsh", command: "ls -l"),
            confirmingDeleteCommandId: .constant(nil),
            onCommandChanged: {}
        )
        .environmentObject(DataManager.shared)
        .previewLayout(.sizeThatFits)
        .padding(.top, 4)
    }
}
