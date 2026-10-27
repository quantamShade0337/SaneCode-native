import SwiftUI

struct StatusBadge: View {
    var label: String
    var systemImage: String = "circle.fill"
    var tint: Color = .secondary

    var body: some View {
        Label(label, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.10), in: Capsule())
            .overlay {
                Capsule().stroke(tint.opacity(0.18), lineWidth: 1)
            }
    }
}
