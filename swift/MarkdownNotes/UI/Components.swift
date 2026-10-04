import SwiftUI

struct TabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            item("Notes", .notes, id: "tab-notes")
            item("Starred", .starred, id: "tab-starred")
            item("Settings", .settings, id: "tab-settings")
        }
        .frame(height: 56)
        .background(alignment: .top) {
            Theme.surface
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) { Theme.separator.frame(height: 1) }
        }
    }

    private func item(_ label: String, _ tab: AppTab, id: String) -> some View {
        let active = selection == tab
        return Button { selection = tab } label: {
            Text(label)
                .font(.system(size: 15, weight: active ? .semibold : .medium))
                .foregroundStyle(active ? Theme.accent : Theme.textTertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

struct ScreenHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Theme.text)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            trailing
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(title: String) { self.init(title: title) { EmptyView() } }
}

struct NoteCard: View {
    let note: Note
    let showSnippet: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Text(note.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                if showSnippet, !note.snippet.isEmpty {
                    RichText(
                        text: TextStyle.plain(note.snippet, font: TextStyle.font(size: 15),
                                              color: .mdTextSecondary, lineHeight: 20, lineBreak: .byTruncatingTail),
                        lineLimit: 2
                    )
                    .padding(.top, 4)
                }
                let tags = note.tags
                if !tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.accent)
                                .lineLimit(1)
                                .fixedSize()
                                .padding(.horizontal, 8)
                                .frame(height: 22)
                                .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 11))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipped()
                    .padding(.top, 8)
                }
                HStack(spacing: 12) {
                    Text(note.dateLabel)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textTertiary)
                    let progress = note.taskProgress
                    if progress.total > 0 {
                        Text("\(progress.done)/\(progress.total) done")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: 0)
                    if note.starred {
                        Text("★")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.star)
                            .frame(height: 16)
                    }
                }
                .padding(.top, 8)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("note-card")
    }
}

struct NoteList: View {
    let notes: [Note]
    let emptyText: String
    let showSnippets: Bool
    let open: (Note) -> Void

    var body: some View {
        if notes.isEmpty {
            Text(emptyText)
                .font(.system(size: 17))
                .foregroundStyle(Theme.textTertiary)
                .accessibilityIdentifier("empty-state")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(notes) { note in
                        NoteCard(note: note, showSnippet: showSnippets) { open(note) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
}

struct PillSwitch: View {
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule().fill(isOn ? Theme.accent : Theme.fill)
                Circle().fill(Color.white).frame(width: 27, height: 27).padding(2)
            }
            .frame(width: 51, height: 31)
            .animation(.easeOut(duration: 0.15), value: isOn)
        }
        .buttonStyle(.plain)
    }
}

/// Horizontally scrolling tag filter for the Notes tab.
struct TagFilterRow: View {
    let tags: [String]
    @Binding var selection: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", selected: selection == nil, id: "tag-filter-all") { selection = nil }
                ForEach(tags, id: \.self) { tag in
                    chip("#\(tag)", selected: selection == tag, id: "tag-filter-\(tag)") { selection = tag }
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 32)
    }

    private func chip(_ label: String, selected: Bool, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: selected ? .semibold : .medium))
                .foregroundStyle(selected ? Color.white : Theme.text)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(selected ? Theme.accent : Theme.surface, in: RoundedRectangle(cornerRadius: 16))
                .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct Toast: View {
    let message: String
    let action: String
    let onAction: () -> Void

    var body: some View {
        HStack {
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Button(action: onAction) {
                Text(action)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.toastAction)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("undo-button")
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Theme.toastBg, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("toast")
    }
}
