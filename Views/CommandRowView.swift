import SwiftUI

struct CommandRowView: View {
    @EnvironmentObject private var dataManager: DataManager
    let command: Command
    let settings: AppSettings
    @Binding var confirmingDeleteCommandId: Int64?
    let onCommandChanged: () -> Void // Unified callback for delete/edit

    @State private var output: String = ""
    @State private var isRunning: Bool = false
    @State private var showingOutput: Bool = false
    // Pid of the running shell; also its process group id (spawned with POSIX_SPAWN_SETPGROUP)
    @State private var runningPid: pid_t? = nil
    @State private var wasInterrupted: Bool = false
    // Completes once the shell is reaped and its output is drained
    @State private var runFinished: DispatchGroup? = nil

    // State for the inline edit form
    @State private var showingEditForm = false
    @State private var editedName: String
    @State private var editedCommand: String
    
    private var isConfirmingDelete: Bool {
        confirmingDeleteCommandId == command.id
    }

    init(command: Command, settings: AppSettings, confirmingDeleteCommandId: Binding<Int64?>, onCommandChanged: @escaping () -> Void) {
        self.command = command
        self.settings = settings
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
                        .foregroundColor(.green.opacity(0.8))
                }
                Spacer()
                
                // Edit Button
                Button(action: {
                    confirmingDeleteCommandId = nil // Reset confirmation on any action
                    showingEditForm.toggle()
                }) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.green)


                // Delete Button
                Button(role: .destructive, action: handleDeleteTap) {
                    Image(systemName: "trash")
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(isConfirmingDelete ? Color.black : Color.green)
                .background(isConfirmingDelete ? Color.green : Color.clear)
                .cornerRadius(4)
                
                // Collapse Output Button
                if showingOutput && !isRunning {
                    Button(action: {
                        confirmingDeleteCommandId = nil // Reset confirmation on any action
                        showingOutput = false
                    }) {
                        Image(systemName: "chevron.down.circle.fill")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.green)
                    .accessibilityLabel("Hide output")
                }

                // Run / Stop Button
                Button(action: {
                    confirmingDeleteCommandId = nil // Reset confirmation on any action
                    if isRunning {
                        stopCommand()
                    } else {
                        showingOutput = true
                        runCommand()
                    }
                }) {
                    Image(systemName: isRunning ? "stop.fill" : "play.fill")
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.green)
                .accessibilityLabel(isRunning ? "Stop \(command.name)" : "Run \(command.name)")
            }
            
            // Inline Edit Form
            if showingEditForm {
                VStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Command name")
                            .font(.caption)
                        TextField("", text: $editedName)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(4)
                            .background(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                        
                        Text("Command")
                            .font(.caption)
                        TextField("", text: $editedCommand)
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
                            // Reset state and hide form
                            editedName = command.name
                            editedCommand = command.command
                            showingEditForm = false
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.green, lineWidth: 1)
                        )
                        Button("Save", action: updateCommand)
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
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green, lineWidth: 1)
                )
        )
        .padding(.top, 4)
    }

    private func handleDeleteTap() {
        if isConfirmingDelete {
            // This is the second click, perform deletion
            guard let commandId = command.id else { return }
            if isRunning {
                stopCommand()
            }
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
        output = ""
        wasInterrupted = false

        // One pipe for both stdout and stderr
        var fds: [Int32] = [0, 0]
        guard pipe(&fds) == 0 else {
            reportError("Failed to run command: could not create pipe (\(String(cString: strerror(errno))))")
            return
        }

        var fileActions: posix_spawn_file_actions_t? = nil
        var attributes: posix_spawnattr_t? = nil
        var defaultSignals = sigset_t()
        sigfillset(&defaultSignals)
        var noBlockedSignals = sigset_t()
        sigemptyset(&noBlockedSignals)
        // Own process group so Stop can signal the shell and every child it spawned.
        // CLOEXEC_DEFAULT keeps the app's other descriptors out of the child.
        let setupResults: [Int32] = [
            posix_spawn_file_actions_init(&fileActions),
            posix_spawn_file_actions_addopen(&fileActions, STDIN_FILENO, "/dev/null", O_RDONLY, 0),
            posix_spawn_file_actions_adddup2(&fileActions, fds[1], STDOUT_FILENO),
            posix_spawn_file_actions_adddup2(&fileActions, fds[1], STDERR_FILENO),
            posix_spawn_file_actions_addclose(&fileActions, fds[0]),
            posix_spawn_file_actions_addclose(&fileActions, fds[1]),
            posix_spawnattr_init(&attributes),
            posix_spawnattr_setsigdefault(&attributes, &defaultSignals),
            posix_spawnattr_setsigmask(&attributes, &noBlockedSignals),
            posix_spawnattr_setpgroup(&attributes, 0),
            posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_CLOEXEC_DEFAULT | POSIX_SPAWN_SETSIGDEF | POSIX_SPAWN_SETSIGMASK)),
        ]
        defer {
            posix_spawn_file_actions_destroy(&fileActions)
            posix_spawnattr_destroy(&attributes)
        }
        if let setupError = setupResults.first(where: { $0 != 0 }) {
            close(fds[0])
            close(fds[1])
            reportError("Failed to run command: could not prepare process (\(String(cString: strerror(setupError))))")
            return
        }

        let shellPath = "/bin/\(settings.shell)"
        let argv: [UnsafeMutablePointer<CChar>?] = [shellPath, "-c", command.command].map { strdup($0) } + [nil]
        defer { argv.forEach { free($0) } }

        var pid: pid_t = 0
        let spawnResult = posix_spawn(&pid, shellPath, &fileActions, &attributes, argv, environ)
        close(fds[1])
        guard spawnResult == 0 else {
            close(fds[0])
            reportError("Failed to run command: \(String(cString: strerror(spawnResult)))")
            return
        }

        let readHandle = FileHandle(fileDescriptor: fds[0], closeOnDealloc: true)
        let manager = dataManager
        let finished = DispatchGroup()
        finished.enter() // pipe drained to EOF
        finished.enter() // shell reaped
        isRunning = true
        runningPid = pid
        runFinished = finished

        // Read until EOF so the tail of the output is never dropped
        DispatchQueue.global(qos: .userInitiated).async {
            var pending = Data()
            while true {
                let chunk: Data
                do {
                    chunk = try readHandle.read(upToCount: 64 * 1024) ?? Data()
                } catch {
                    let errorMessage = "Failed to read command output: \(error.localizedDescription)"
                    DispatchQueue.main.async {
                        manager.latestError = errorMessage
                        self.output += "\n" + errorMessage
                    }
                    break
                }
                if chunk.isEmpty { break }
                pending.append(chunk)
                let text = Self.decodeUTF8Prefix(&pending)
                DispatchQueue.main.async {
                    self.output += text
                }
            }
            let tail = String(decoding: pending, as: UTF8.self)
            DispatchQueue.main.async {
                self.output += tail
                finished.leave()
            }
        }

        DispatchQueue.global(qos: .utility).async {
            var status: Int32 = 0
            while waitpid(pid, &status, 0) == -1 && errno == EINTR {}
            finished.leave()
        }

        finished.notify(queue: .main) {
            if self.wasInterrupted {
                self.output += (self.output.isEmpty || self.output.hasSuffix("\n") ? "" : "\n") + "[interrupted]"
            }
            self.isRunning = false
            self.runningPid = nil
            self.runFinished = nil
        }
    }

    private func stopCommand() {
        guard let pid = runningPid, let finished = runFinished else { return }
        wasInterrupted = true
        let manager = dataManager
        // ESRCH means the group already exited, which is not a failure
        if killpg(pid, SIGTERM) != 0 && errno != ESRCH {
            reportError("Failed to stop command: \(String(cString: strerror(errno)))")
        }
        // Escalate if this run is still alive. Until the run finishes the shell is not
        // reaped, so its pid (the group id) cannot have been reused by another process.
        // Captures no view state, so it still fires when the row was deleted mid-run.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard finished.wait(timeout: .now()) == .timedOut else { return }
            if killpg(pid, SIGKILL) != 0 && errno != ESRCH {
                let errorMessage = "Failed to force-stop command: \(String(cString: strerror(errno)))"
                manager.latestError = errorMessage
                self.output += "\n" + errorMessage
            }
        }
    }

    private func reportError(_ message: String) {
        dataManager.latestError = message
        output += (output.isEmpty ? "" : "\n") + message
    }

    // Decodes the longest valid UTF-8 prefix and leaves an incomplete trailing
    // character (at most 3 bytes) in `data` for the next chunk.
    nonisolated private static func decodeUTF8Prefix(_ data: inout Data) -> String {
        for trailing in 0...min(3, data.count) {
            if let text = String(data: data.prefix(data.count - trailing), encoding: .utf8) {
                data = Data(data.suffix(trailing))
                return text
            }
        }
        // Genuinely invalid bytes: decode with replacement characters instead of dropping them
        let text = String(decoding: data, as: UTF8.self)
        data.removeAll()
        return text
    }
}

struct CommandRowView_Previews: PreviewProvider {
    static var previews: some View {
        CommandRowView(
            command: Command(id: 1, name: "List Files", command: "ls -l"),
            settings: AppSettings(shell: "zsh"),
            confirmingDeleteCommandId: .constant(nil),
            onCommandChanged: {}
        )
        .environmentObject(DataManager.shared)
        .previewLayout(.sizeThatFits)
        .padding(.top, 4)
    }
}
