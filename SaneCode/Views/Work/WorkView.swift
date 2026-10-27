import SwiftUI

struct WorkView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        Group {
            if let repo = app.selectedRepository, let room = app.selectedRoom {
                AgentRoomView(
                    repository: repo,
                    viewModel: AgentRoomViewModel(room: room)
                )
                .id(room.id)
            } else {
                EmptyStateView(title: "No room selected", message: "Create a room to start work.", systemImage: "square.stack")
            }
        }
    }
}
