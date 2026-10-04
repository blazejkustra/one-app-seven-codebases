import SwiftUI

struct SettingsScreen: View {
    @Environment(NoteStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Settings")

            VStack(spacing: 0) {
                Button { store.toggleSortOrder() } label: {
                    row("Sort by") {
                        Text(store.sortOrder.label)
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("sort-row")

                separator

                row("Show snippets") {
                    PillSwitch(isOn: store.showSnippets) { store.setShowSnippets(!store.showSnippets) }
                        .accessibilityLabel("Show snippets")
                        .accessibilityValue(store.showSnippets ? "1" : "0")
                        .accessibilityAddTraits(.isToggle)
                        .accessibilityIdentifier("snippets-switch")
                }

                separator

                Button { store.cycleAppearance() } label: {
                    row("Appearance") {
                        Text(store.appearance.label)
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("appearance-row")

                separator

                row("Notes") {
                    Text("\(store.notes.count)")
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.textTertiary)
                        .accessibilityIdentifier("notes-count")
                }
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Button { store.resetSampleNotes() } label: {
                Text("Reset sample notes")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.danger)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("reset-button")
            .padding(.horizontal, 16)
            .padding(.top, 24)

            Text("Markdown Notes · v1.0")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 16)

            Spacer(minLength: 0)
        }
    }

    private var separator: some View {
        Theme.separator.frame(height: 1).padding(.leading, 16)
    }

    private func row<Trailing: View>(_ label: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17))
                .foregroundStyle(Theme.text)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .contentShape(Rectangle())
    }
}
