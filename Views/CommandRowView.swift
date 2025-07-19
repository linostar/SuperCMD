import SwiftUI

struct CommandRowView: View {
    let command: Command

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(command.name)
                    .font(.headline)
                Text(command.command)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: runCommand) {
                Image(systemName: "play.fill")
            }
        }
        .padding(.vertical, 4)
    }

    private func runCommand() {
        // Placeholder: Implement the logic to execute the shell command.
        print("Running command: \(command.command)")
    }
}

struct CommandRowView_Previews: PreviewProvider {
    static var previews: some View {
        CommandRowView(command: Command(id: 1, name: "List Files", shell: "zsh", command: "ls -l"))
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
