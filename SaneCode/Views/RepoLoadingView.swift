import SwiftUI

struct RepoLoadingView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)
            Text("Scanning repository...")
                .font(.title2.weight(.semibold))
            VStack(alignment: .leading, spacing: 8) {
                ForEach(app.scanSteps, id: \.self) { step in
                    HStack(spacing: 8) {
                        Image(systemName: step == "Scanning repository..." ? "circle.dotted" : "checkmark.circle.fill")
                            .foregroundStyle(step == "Scanning repository..." ? Color.secondary : Color.green)
                        Text(step)
                    }
                }
            }
            .frame(width: 420, alignment: .leading)
        }
        .padding(40)
    }
}
