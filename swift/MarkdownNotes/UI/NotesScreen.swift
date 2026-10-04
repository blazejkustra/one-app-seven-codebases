import SwiftUI

struct NotesScreen: View {
    @Environment(NoteStore.self) private var store
    @Binding var query: String
    @Binding var selectedTag: String?
    @FocusState private var searchFocused: Bool
    let open: (Note) -> Void
    let create: () -> Void

    var body: some View {
        let allTags = store.allTags
        let activeTag = selectedTag.flatMap { allTags.contains($0) ? $0 : nil }
        let results = store.notes(matching: query, tag: activeTag)
        VStack(spacing: 0) {
            ScreenHeader(title: "Notes") {
                Button(action: create) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Theme.accent, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("New note")
                .accessibilityIdentifier("add-note-button")
            }

            TextField("", text: $query, prompt: Text("Search notes").foregroundStyle(Theme.textTertiary))
                .font(.system(size: 17))
                .foregroundStyle(Theme.text)
                .tint(Theme.accent)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .frame(height: 40)
                .padding(.horizontal, 12)
                .background(Theme.fill, in: RoundedRectangle(cornerRadius: 10))
                .contentShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture { searchFocused = true }
                .focused($searchFocused)
                .accessibilityIdentifier("search-input")
                .padding(.horizontal, 16)
                .padding(.top, 4)

            TagFilterRow(tags: allTags, selection: $selectedTag)
                .padding(.top, 12)

            NoteList(
                notes: results,
                emptyText: store.notes.isEmpty ? "No notes yet" : "No notes found",
                showSnippets: store.showSnippets,
                open: open
            )
            .padding(.top, 12)
        }
        .onAppear { resetMissingTag(allTags) }
        .onChange(of: allTags) { _, tags in resetMissingTag(tags) }
    }

    /// A selected tag that no longer exists on any note falls back to `All`.
    private func resetMissingTag(_ tags: [String]) {
        if let tag = selectedTag, !tags.contains(tag) { selectedTag = nil }
    }
}

struct StarredScreen: View {
    @Environment(NoteStore.self) private var store
    let open: (Note) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Starred")
            NoteList(
                notes: store.starredNotes,
                emptyText: "No starred notes",
                showSnippets: store.showSnippets,
                open: open
            )
            .padding(.top, 12)
        }
    }
}
