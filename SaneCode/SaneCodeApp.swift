//
//  SaneCodeApp.swift
//  SaneCode
//
//  Created by Ethan Soh on 4/5/26.
//

import SwiftUI

@main
struct SanecodeApp: App {
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
                .frame(minWidth: 1180, minHeight: 760)
                .onOpenURL { url in
                    appViewModel.handleIncomingURL(url)
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Room") {
                    appViewModel.showNewRoom = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandMenu("Sanecode") {
                Button("Open Repository") {
                    appViewModel.openRepository()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Command Palette") {
                    appViewModel.showCommandPalette = true
                }
                .keyboardShortcut("k", modifiers: .command)

                Button("Toggle Terminal") {
                    appViewModel.isTerminalDrawerOpen.toggle()
                }
                .keyboardShortcut("j", modifiers: .command)

                Button("Show Changes") {
                    appViewModel.selectedMainTab = .changes
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView(viewModel: SettingsViewModel(settingsStore: appViewModel.settingsStore))
                .frame(width: 760, height: 580)
        }
    }
}
