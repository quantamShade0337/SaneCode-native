import SwiftUI

struct FileSearchView: View {
    @Binding var query: String

    var body: some View {
        TextField("Search files...", text: $query)
            .textFieldStyle(.roundedBorder)
    }
}
