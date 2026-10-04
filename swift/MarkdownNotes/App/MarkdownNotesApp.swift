import SwiftUI

@main
struct MarkdownNotesApp: App {
    @State private var store = NoteStore.makeDefault()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}
