import SwiftUI

enum EditorMode { case edit, preview }

struct EditorScreen: View {
    @Environment(NoteStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    let route: EditorRoute
    let onBack: () -> Void
    let onDelete: () -> Void

    @State private var mode: EditorMode
    @State private var text: String = ""
    @State private var focusRequest = false

    init(route: EditorRoute, onBack: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.route = route
        self.onBack = onBack
        self.onDelete = onDelete
        _mode = State(initialValue: route.isNew ? .edit : .preview)
        _focusRequest = State(initialValue: route.isNew)
    }

    private var note: Note? { store.note(id: route.noteID) }

    var body: some View {
        VStack(spacing: 0) {
            navRow
            SegmentedControl(mode: $mode)
                .padding(.horizontal, 16)
                .padding(.top, 4)

            Group {
                switch mode {
                case .edit:
                    MarkdownTextView(text: $text, focusRequest: $focusRequest)
                        .padding(16)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                case .preview:
                    ScrollView {
                        MarkdownView(source: text)
                            .environment(\.toggleTask) { line in
                                text = Tasks.toggle(in: text, line: line)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("preview-view")
                }
            }
            .padding(.top, 12)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear { text = note?.body ?? "" }
        .onChange(of: text) { _, newValue in
            store.updateBody(id: route.noteID, body: newValue)
        }
    }

    private var navRow: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                Text("‹ Notes")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.accent)
                    .padding(.leading, 16)
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notes")
            .accessibilityIdentifier("back-button")

            Spacer()

            Button { ShareSheet.present(text: text) } label: {
                Text("Share")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.accent)
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("share-button")
            .padding(.trailing, 12)

            Button(action: onDelete) {
                Text("Delete")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.danger)
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("delete-button")
            .padding(.trailing, 12)

            let starred = note?.starred ?? false
            Button { store.toggleStar(id: route.noteID) } label: {
                Text(starred ? "★" : "☆")
                    .font(.system(size: 22))
                    .foregroundStyle(starred ? Theme.star : Theme.textTertiary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(starred ? "Unstar" : "Star")
            .accessibilityValue(starred ? "starred" : "not starred")
            .accessibilityIdentifier("star-button")
            .padding(.trailing, 16)
        }
        .frame(height: 44)
        .background(Theme.bg)
    }
}

struct SegmentedControl: View {
    @Binding var mode: EditorMode

    var body: some View {
        HStack(spacing: 0) {
            segment("Edit", .edit, id: "mode-edit")
            segment("Preview", .preview, id: "mode-preview")
        }
        .padding(2)
        .frame(height: 36)
        .background(Theme.fill, in: RoundedRectangle(cornerRadius: 9))
    }

    private func segment(_ label: String, _ value: EditorMode, id: String) -> some View {
        let selected = mode == value
        return Button { mode = value } label: {
            Text(label)
                .font(.system(size: 15, weight: selected ? .semibold : .medium))
                .foregroundStyle(selected ? Theme.text : Theme.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if selected { RoundedRectangle(cornerRadius: 7).fill(Theme.surface) }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
