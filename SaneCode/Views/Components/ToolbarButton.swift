import SwiftUI

struct ToolbarButton: View {
    var title: String
    var systemImage: String
    var role: ButtonRole?
    var action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .buttonBorderShape(.roundedRectangle(radius: 6))
    }
}
