import SwiftUI

struct TerminalTabBarView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        Picker("", selection: Binding(
            get: { app.terminalViewModel.selectedTerminalTab },
            set: { app.terminalViewModel.selectedTerminalTab = $0 }
        )) {
            ForEach(CommandKind.allCases) { kind in
                Text(kind.rawValue).tag(kind)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 260)
    }
}
