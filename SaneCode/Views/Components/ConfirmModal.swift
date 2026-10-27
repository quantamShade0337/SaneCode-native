import SwiftUI

struct ConfirmModal: View {
    var title: String
    var message: String
    var confirmTitle: String
    var role: ButtonRole? = nil
    var onCancel: () -> Void
    var onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title).font(.title3.weight(.semibold))
            Text(message).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                Button(confirmTitle, role: role, action: onConfirm)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
