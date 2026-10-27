import SwiftUI

struct CodeIntelligenceView: View {
    var rootPath: String
    var openFile: (String) -> Void
    @State private var report = CodeIntelligenceReport(diagnostics: [], symbols: [])
    @State private var query = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Code Intelligence")
                    .font(.headline)
                Spacer()
                Button("Refresh") { scan() }
                    .controlSize(.small)
            }
            TextField("Find symbols...", text: $query)
                .textFieldStyle(.roundedBorder)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    section("Diagnostics") {
                        if report.diagnostics.isEmpty {
                            Text("No lightweight diagnostics found.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(report.diagnostics.prefix(20)) { item in
                                Button {
                                    openFile(item.path)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.message)
                                            .font(.caption.weight(.semibold))
                                        Text("\(item.path):\(item.line)")
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    section("Symbols") {
                        ForEach(filteredSymbols.prefix(50)) { symbol in
                            Button {
                                openFile(symbol.path)
                            } label: {
                                HStack {
                                    Text(symbol.name)
                                        .font(.caption.weight(.semibold))
                                    Spacer()
                                    Text(symbol.kind)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Text("\(symbol.path):\(symbol.line)")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(12)
        .onAppear(perform: scan)
    }

    private var filteredSymbols: [CodeSymbol] {
        guard !query.isEmpty else { return report.symbols }
        return report.symbols.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.path.localizedCaseInsensitiveContains(query) }
    }

    private func scan() {
        report = CodeIntelligenceScanner().scan(rootPath: rootPath)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }
}
