import SwiftUI

enum AppTab: Hashable { case notes, starred, settings }

struct EditorRoute: Equatable {
    let noteID: String
    let isNew: Bool
}

struct RootView: View {
    @Environment(NoteStore.self) private var store
    @State private var tab: AppTab = .notes
    @State private var route: EditorRoute?
    @State private var query = ""
    @State private var selectedTag: String?
    @State private var deleted: Note?          // latest deletion, undoable while the toast shows
    @State private var toastToken = UUID()

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            // The tab layer is removed while the editor is shown so only the
            // editor is visible to accessibility / UI tests.
            if route == nil {
            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case .notes: NotesScreen(query: $query, selectedTag: $selectedTag, open: open, create: create)
                    case .starred: StarredScreen(open: open)
                    case .settings: SettingsScreen()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .overlay(alignment: .bottom) {
                    if deleted != nil {
                        Toast(message: "Note deleted", action: "Undo", onAction: undo)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                            .transition(.opacity)
                    }
                }
                TabBar(selection: $tab)
            }
            .ignoresSafeArea(.keyboard)
            }

            if let route {
                EditorScreen(route: route, onBack: close, onDelete: deleteCurrent)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .onAppear { applyAppearance(store.appearance) }
        .onChange(of: store.appearance) { _, value in applyAppearance(value) }
    }

    /// Applies the Appearance setting to every window: UIKit text, keyboard and status bar follow it.
    /// `.unspecified` (System) tracks the iOS appearance live.
    private func applyAppearance(_ appearance: Appearance) {
        let style: UIUserInterfaceStyle = switch appearance {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
        for scene in UIApplication.shared.connectedScenes {
            for window in (scene as? UIWindowScene)?.windows ?? [] {
                window.overrideUserInterfaceStyle = style
            }
        }
    }

    private func open(_ note: Note) {
        withAnimation(.easeOut(duration: 0.25)) { route = EditorRoute(noteID: note.id, isNew: false) }
    }

    private func create() {
        let note = store.createNote()
        withAnimation(.easeOut(duration: 0.25)) { route = EditorRoute(noteID: note.id, isNew: true) }
    }

    private func deleteCurrent() {
        guard let id = route?.noteID else { return }
        let removed = store.deleteNote(id: id)
        withAnimation(.easeOut(duration: 0.25)) { route = nil }
        guard let removed else { return }
        // A newer deletion replaces the toast; only it can be undone.
        let token = UUID()
        toastToken = token
        deleted = removed
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            if toastToken == token { withAnimation { deleted = nil } }
        }
    }

    private func undo() {
        guard let note = deleted else { return }
        store.restore(note)
        toastToken = UUID()
        withAnimation { deleted = nil }
    }

    private func close() {
        if let id = route?.noteID { store.finishEditing(id: id) }
        withAnimation(.easeOut(duration: 0.25)) { route = nil }
    }
}
