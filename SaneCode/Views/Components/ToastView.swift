import SwiftUI

struct ToastView: View {
    var text: String
    var systemImage: String = "checkmark.circle.fill"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.green)
            Text(text)
                .font(.callout.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        }
    }
}
