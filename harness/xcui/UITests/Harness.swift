import XCTest

// Framework-agnostic driver: every implementation is reached only through the
// accessibility identifiers required by spec/SPEC.md §5.
let env = ProcessInfo.processInfo.environment
let bundleId = env["TARGET_BUNDLE"] ?? "com.mdnotes.swift"
let outDir = env["OUT_DIR"] ?? "/tmp/mdnotes"

let seedTitles = ["Welcome to Markdown Notes", "Grocery list", "Meeting notes", "Ideas"]

class Base: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication(bundleIdentifier: bundleId)
        try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
    }

    func el(_ id: String) -> XCUIElement { app.descendants(matching: .any).matching(identifier: id).firstMatch }
    func all(_ id: String) -> XCUIElementQuery { app.descendants(matching: .any).matching(identifier: id) }
    func containing(_ text: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text))
    }

    @discardableResult func wait(_ e: XCUIElement, _ t: TimeInterval = 10) -> Bool { e.waitForExistence(timeout: t) }

    func tap(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
        let e = el(id)
        XCTAssertTrue(wait(e), "missing element '\(id)'", file: file, line: line)
        scrollIntoView(e)
        tapPoint(e.frame.midX, e.frame.midY)
        settle()
    }

    /// Horizontal rows (tag filters) may hold the target off-screen: drag the row until it is visible.
    func scrollIntoView(_ e: XCUIElement) {
        let w = app.frame.width
        for i in 0..<12 {
            let f = e.frame
            // some stacks (Flutter) report an empty frame for children scrolled out of view
            let hidden = f.width < 1 || f.height < 1
            if !hidden && f.minX >= 0 && f.maxX <= w { return }
            var rowY = f.midY
            if hidden {
                let chips = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'tag-filter-'"))
                guard let v = chips.allElementsBoundByIndex.first(where: { $0.frame.width >= 1 }) else { return }
                rowY = v.frame.midY
            }
            let dir: CGFloat = hidden ? (i < 4 ? -1 : 1) : (f.maxX > w ? -1 : 1)
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: w / 2, dy: rowY))
            let end = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: w / 2 + dir * 150, dy: rowY))
            start.press(forDuration: 0.05, thenDragTo: end)
            settle(0.5)
        }
    }

    func tapPoint(_ x: CGFloat, _ y: CGFloat) {
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y)).tap()
    }

    func settle(_ s: Double = 0.8) { Thread.sleep(forTimeInterval: s) }

    func launch() {
        app.launch()
        XCTAssertTrue(wait(el("note-card"), 30), "no note-card after launch")
        settle(1.0)
    }

    func relaunch() {
        app.terminate()
        launch()
    }

    /// Visible note cards, de-duplicated (some UI stacks put the identifier on nested views).
    func cardFrames() -> [CGRect] {
        let screenH = app.frame.height
        let frames = all("note-card").allElementsBoundByIndex
            .map { $0.frame }
            .filter { $0.width > 100 && $0.height > 30 && $0.minY < screenH - 90 && $0.maxY > 0 }
        var uniq: [CGRect] = []
        for f in frames.sorted(by: { $0.width * $0.height > $1.width * $1.height }) where
            !uniq.contains(where: { $0.insetBy(dx: -1, dy: -1).contains(f) }) {
            uniq.append(f)
        }
        return uniq.sorted { $0.minY < $1.minY }
    }

    func tapCard(_ i: Int, file: StaticString = #filePath, line: UInt = #line) {
        let cards = cardFrames()
        XCTAssertTrue(cards.count > i, "expected > \(i) cards, got \(cards.count)", file: file, line: line)
        tapPoint(cards[i].midX, cards[i].midY)
        settle()
    }

    func openCard(titled title: String, file: StaticString = #filePath, line: UInt = #line) {
        let limit = app.frame.height - 130   // keep clear of the tab bar / toast area
        for _ in 0..<4 {
            // not found at all (some stacks hide off-screen rows from accessibility) or too low: scroll down
            if let f = textFrame(title), f.minY + 12 < limit { break }
            let x = app.frame.width / 2
            app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: 600))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: 350)))
            settle(0.8)
        }
        guard let f = textFrame(title) else { return XCTFail("no card titled \(title)", file: file, line: line) }
        tapPoint(f.midX, min(f.midY, f.minY + 12))
        settle()
    }

    /// Smallest on-screen element whose label/value contains `text`.
    func textFrame(_ text: String) -> CGRect? {
        containing(text).allElementsBoundByIndex.map { $0.frame }
            .filter { $0.width > 0 && $0.height > 0 }
            .min { $0.width * $0.height < $1.width * $1.height }
    }

    func textOf(_ id: String) -> String {
        let e = el(id)
        guard wait(e, 5) else { return "" }
        var parts = [e.label, (e.value as? String) ?? ""]
        parts += e.descendants(matching: .any).allElementsBoundByIndex.flatMap { [$0.label, ($0.value as? String) ?? ""] }
        return parts.joined(separator: " ")
    }

    var keyboardUp: Bool { app.keyboards.count > 0 && app.keyboards.firstMatch.frame.height > 50 }

    /// Taps near the bottom-right of the editor so the caret lands at the end of the text.
    func focusEditorEnd() {
        let e = el("editor-input")
        XCTAssertTrue(wait(e), "missing editor-input")
        let f = e.frame
        tapPoint(f.maxX - 20, f.maxY - 20)
        settle(0.6)
    }

    func type(_ s: String) { app.typeText(s); settle(0.4) }
    func deleteChars(_ n: Int) { app.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: n)); settle(0.4) }

    func todayLabel() -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US"); f.dateFormat = "MMM d, yyyy"
        return f.string(from: Date())
    }

    func assertOrder(_ titles: [String], file: StaticString = #filePath, line: UInt = #line) {
        let ys = titles.map { textFrame($0)?.minY ?? -1 }
        XCTAssertFalse(ys.contains(-1), "missing titles: \(zip(titles, ys).filter { $0.1 < 0 }.map { $0.0 })", file: file, line: line)
        XCTAssertEqual(ys, ys.sorted(), "wrong order for \(titles): \(ys)", file: file, line: line)
    }

    /// Average luminance (0-255) of a rect (in points) of the current screen.
    func luma(_ r: CGRect) -> Double {
        let img = XCUIScreen.main.screenshot().image
        guard let cg = img.cgImage, let data = cg.dataProvider?.data, let p = CFDataGetBytePtr(data) else { return -1 }
        let scale = CGFloat(cg.width) / img.size.width
        let bpp = cg.bitsPerPixel / 8, bpr = cg.bytesPerRow
        var sum = 0.0, n = 0.0
        for y in stride(from: Int(r.minY * scale), to: Int(r.maxY * scale), by: 3) {
            for x in stride(from: Int(r.minX * scale), to: Int(r.maxX * scale), by: 3) {
                let o = y * bpr + x * bpp
                sum += 0.299 * Double(p[o]) + 0.587 * Double(p[o + 1]) + 0.114 * Double(p[o + 2]); n += 1
            }
        }
        return n > 0 ? sum / n : -1
    }

    func shot(_ name: String) {
        settle(1.5)
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try? png.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
    }
}

// MARK: - Fidelity screenshots (fresh install, seed data)

final class Screens: Base {
    func testScreens() {
        launch()
        shot("01-notes")
        openCard(titled: seedTitles[0])
        XCTAssertTrue(wait(el("preview-view")))
        shot("02-editor-preview")
        tap("mode-edit")
        shot("03-editor-edit")
        tap("back-button")
        tap("tab-starred")
        shot("04-starred")
        tap("tab-settings")
        shot("05-settings")
    }
}

final class ScreensFinal: Base {
    func testScreensFinal() {
        launch()
        shot("01-notes")
        openCard(titled: seedTitles[0])
        XCTAssertTrue(wait(el("preview-view")))
        shot("02-editor-preview")
        tap("mode-edit")
        shot("03-editor-edit")
        tap("back-button")
        openCard(titled: "Grocery list")
        shot("06-checklist-preview")
        tap("back-button")
        tap("tab-starred")
        shot("04-starred")
        tap("tab-settings")
        shot("05-settings")
        tap("appearance-row")
        tap("appearance-row")
        tap("tab-notes")
        shot("07-notes-dark")
    }
}

// MARK: - Hidden QA checklist (each test runs on a fresh install)

final class QA: Base {
    func test01_seedNotesInOrder() {
        launch()
        XCTAssertEqual(cardFrames().count, 4, "seed should show 4 cards")
        assertOrder(seedTitles)
    }

    func test02_cardShowsSnippetAndDate() {
        launch()
        XCTAssertNotNil(textFrame("Oat milk Sourdough bread"), "snippet not rendered as specified")
        XCTAssertNotNil(textFrame("Oct 1, 2026"), "date label missing / wrong format")
        XCTAssertNil(textFrame("**"), "markdown markers leak into list")
    }

    func test03_existingNoteOpensInPreview() {
        launch()
        openCard(titled: seedTitles[0])
        XCTAssertTrue(wait(el("preview-view")), "preview-view missing")
        XCTAssertFalse(el("editor-input").exists && el("editor-input").isHittable, "editor visible in preview mode")
    }

    func test04_previewRendersMarkdown() {
        launch()
        openCard(titled: seedTitles[0])
        XCTAssertTrue(wait(el("preview-view")))
        XCTAssertNotNil(textFrame("What works"), "heading text missing")
        XCTAssertNil(textFrame("## "), "raw heading markers in preview")
        XCTAssertNil(textFrame("**"), "raw bold markers in preview")
        XCTAssertNil(textFrame("```"), "raw code fence in preview")
    }

    func test05_editModeShowsRawMarkdownWithoutKeyboard() {
        launch()
        openCard(titled: seedTitles[0])
        tap("mode-edit")
        let v = (el("editor-input").value as? String) ?? ""
        XCTAssertTrue(v.contains("**Markdown**"), "editor does not show raw markdown: \(v.prefix(80))")
        XCTAssertFalse(keyboardUp, "keyboard opened when switching to Edit")
    }

    func test06_starShowsInStarredTab() {
        launch()
        openCard(titled: "Grocery list")
        tap("star-button")
        tap("back-button")
        tap("tab-starred")
        XCTAssertEqual(cardFrames().count, 3)
        XCTAssertNotNil(textFrame("Grocery list"))
    }

    func test07_searchFiltersAndShowsEmptyState() {
        launch()
        tap("search-input")
        type("blue")
        settle()
        XCTAssertEqual(cardFrames().count, 1, "search 'blue' should match one note")
        XCTAssertNotNil(textFrame("Grocery list"))
        deleteChars(4)
        settle()
        XCTAssertEqual(cardFrames().count, 4, "clearing search should restore all notes")
        type("zzz")
        settle()
        XCTAssertTrue(wait(el("empty-state"), 3), "no empty-state")
        XCTAssertTrue(textOf("empty-state").contains("No notes found"))
    }

    func test08_newNoteOpensFocusedEditor() {
        launch()
        tap("add-note-button")
        XCTAssertTrue(wait(el("editor-input")), "editor-input missing")
        settle()
        XCTAssertTrue(keyboardUp, "keyboard not shown for new note")
        let v = (el("editor-input").value as? String) ?? ""
        XCTAssertTrue(v.contains("# New note"), "new note body wrong: \(v)")
    }

    func test09_newNoteIsSavedAtTop() {
        launch()
        tap("add-note-button")
        focusEditorEnd()
        type("Hello world")
        tap("back-button")
        assertOrder(["New note", seedTitles[0]])
        XCTAssertNotNil(textFrame("Hello world"), "typed text not in snippet")
        tap("tab-settings")
        XCTAssertTrue(textOf("notes-count").contains("5"), "count: \(textOf("notes-count"))")
    }

    func test10_emptyNoteIsDeleted() {
        launch()
        tap("add-note-button")
        focusEditorEnd()
        deleteChars(30)
        tap("back-button")
        XCTAssertEqual(cardFrames().count, 4, "empty note should be deleted")
    }

    func test11_keyboardDoesNotCoverEditor() {
        launch()
        tap("add-note-button")
        settle(1.0)
        XCTAssertTrue(keyboardUp)
        let input = el("editor-input").frame, kb = app.keyboards.firstMatch.frame
        XCTAssertLessThanOrEqual(input.maxY, kb.minY + 2, "editor \(input) runs under keyboard \(kb)")
    }

    func test12_editUpdatesDateOrderAndPersists() {
        launch()
        openCard(titled: "Ideas")
        tap("mode-edit")
        focusEditorEnd()
        type(" Extra")
        tap("back-button")
        assertOrder(["Ideas", seedTitles[0]])
        XCTAssertNotNil(textFrame(todayLabel()), "updated date not shown")
        app.terminate()
        launch()
        assertOrder(["Ideas", seedTitles[0]])
        XCTAssertNotNil(textFrame("Extra"), "edit lost after relaunch")
    }

    func test13_starPersistsAfterImmediateKill() {
        launch()
        openCard(titled: "Ideas")
        tap("star-button")
        tap("back-button")
        app.terminate()
        launch()
        tap("tab-starred")
        XCTAssertNotNil(textFrame("Ideas"), "star lost after relaunch")
    }

    func test14_sortByTitle() {
        launch()
        tap("tab-settings")
        tap("sort-row")
        XCTAssertTrue(textOf("sort-row").contains("Title") || textFrame("Title") != nil, "sort value not shown")
        tap("tab-notes")
        assertOrder(["Grocery list", "Ideas", "Meeting notes", seedTitles[0]])
        relaunch()
        assertOrder(["Grocery list", "Ideas", "Meeting notes", seedTitles[0]])
    }

    func test15_hideSnippets() {
        launch()
        tap("tab-settings")
        tap("snippets-switch")
        tap("tab-notes")
        XCTAssertNil(textFrame("Oat milk"), "snippets still visible")
        XCTAssertEqual(cardFrames().count, 4)
    }

    func test16_notesCount() {
        launch()
        tap("tab-settings")
        XCTAssertTrue(textOf("notes-count").contains("4"), "count: \(textOf("notes-count"))")
        tap("tab-notes")
        tap("add-note-button")
        tap("back-button")
        tap("tab-settings")
        XCTAssertTrue(textOf("notes-count").contains("5"), "count after add: \(textOf("notes-count"))")
    }

    func test17_resetRestoresSeed() {
        launch()
        openCard(titled: "Grocery list")
        tap("star-button")
        tap("back-button")
        tap("add-note-button")
        tap("back-button")
        tap("tab-settings")
        tap("reset-button")
        tap("tab-notes")
        XCTAssertEqual(cardFrames().count, 4)
        assertOrder(seedTitles)
        tap("tab-starred")
        XCTAssertEqual(cardFrames().count, 2)
    }

    func test18_backReturnsToStarredTab() {
        launch()
        tap("tab-starred")
        tapCard(0)
        XCTAssertTrue(wait(el("back-button")))
        tap("back-button")
        XCTAssertFalse(el("search-input").exists, "returned to Notes tab instead of Starred")
        XCTAssertEqual(cardFrames().count, 2)
    }

    func test19_starredEmptyState() {
        launch()
        tap("tab-starred")
        for _ in 0..<2 {
            tapCard(0)
            tap("star-button")
            tap("back-button")
        }
        XCTAssertTrue(wait(el("empty-state"), 3), "no empty-state")
        XCTAssertTrue(textOf("empty-state").contains("No starred notes"))
    }

    func test20_allIdentifiersPresent() {
        launch()
        var missing: [String] = []
        func check(_ ids: [String]) { for id in ids where !wait(el(id), 3) { missing.append(id) } }
        check(["tab-notes", "tab-starred", "tab-settings", "add-note-button", "search-input", "note-card"])
        openCard(titled: seedTitles[0])
        check(["back-button", "star-button", "mode-edit", "mode-preview", "preview-view"])
        tap("mode-edit")
        check(["editor-input"])
        tap("back-button")
        tap("tab-settings")
        check(["sort-row", "snippets-switch", "notes-count", "reset-button"])
        XCTAssertTrue(missing.isEmpty, "missing identifiers: \(missing)")
    }

    // ---- Iteration 2: tags
    func test21_tagFilter() {
        launch()
        tap("tag-filter-work")
        XCTAssertEqual(cardFrames().count, 1)
        XCTAssertNotNil(textFrame("Meeting notes"))
        tap("tag-filter-all")
        XCTAssertEqual(cardFrames().count, 4)
    }

    func test22_tagChipsAndCleanSnippet() {
        launch()
        XCTAssertNotNil(textFrame("#shopping"), "tag chip missing")
        XCTAssertNil(textFrame("chocolate home"), "tags leak into snippet")
        XCTAssertNotNil(el("tag-filter-ideas").exists ? el("tag-filter-ideas") : nil, "tag-filter-ideas missing")
    }

    func test23_tagFilterCombinesWithSearch() {
        launch()
        tap("tag-filter-home")
        tap("search-input")
        type("milk")
        settle()
        XCTAssertEqual(cardFrames().count, 1)
        deleteChars(4)
        type("meeting")
        settle()
        XCTAssertTrue(wait(el("empty-state"), 3), "tag + search should find nothing")
    }

    func test24_newTagAppearsInFilterRow() {
        launch()
        tap("add-note-button")
        focusEditorEnd()
        type("Call the bank #urgent")
        tap("back-button")
        XCTAssertTrue(wait(el("tag-filter-urgent"), 3), "new tag not in filter row")
        tap("tag-filter-urgent")
        XCTAssertEqual(cardFrames().count, 1)
    }

    // ---- Iteration 3: checklists
    func test25_checklistProgressOnCard() {
        launch()
        XCTAssertNotNil(textFrame("2/4 done"), "progress label missing")
    }

    func test26_toggleTaskRewritesMarkdownAndPersists() {
        launch()
        openCard(titled: "Grocery list")
        let t = el("task-1")
        XCTAssertTrue(wait(t), "task-1 missing")
        XCTAssertEqual(t.value as? String, "unchecked")
        tapPoint(t.frame.midX, t.frame.midY)
        settle()
        XCTAssertEqual(el("task-1").value as? String, "checked")
        tap("mode-edit")
        let v = (el("editor-input").value as? String) ?? ""
        XCTAssertTrue(v.contains("- [x] Sourdough bread"), "markdown not rewritten")
        tap("back-button")
        XCTAssertNotNil(textFrame("3/4 done"))
        assertOrder(["Grocery list", seedTitles[0]])
        relaunch()
        XCTAssertNotNil(textFrame("3/4 done"), "toggle lost after relaunch")
    }

    // ---- Iteration 4: delete + undo
    func test27_deleteAndUndo() {
        launch()
        openCard(titled: "Meeting notes")
        tap("delete-button")
        XCTAssertTrue(wait(el("toast"), 3), "no toast")
        XCTAssertEqual(cardFrames().count, 3)
        tap("undo-button")
        XCTAssertEqual(cardFrames().count, 4)
        assertOrder(seedTitles)
        XCTAssertNotNil(textFrame("Sep 28, 2026"), "undo did not restore updatedAt")
    }

    func test28_toastExpiresAndDeletePersists() {
        launch()
        openCard(titled: "Ideas")
        tap("delete-button")
        XCTAssertTrue(wait(el("toast"), 3))
        settle(5.5)
        XCTAssertFalse(el("toast").exists, "toast did not disappear after 4s")
        relaunch()
        XCTAssertEqual(cardFrames().count, 3)
        XCTAssertNil(textFrame("habit tracker"))
    }

    func test29_deleteFromStarredReturnsToStarred() {
        launch()
        tap("tab-starred")
        tapCard(0)
        tap("delete-button")
        XCTAssertFalse(el("search-input").exists, "went to Notes instead of Starred")
        XCTAssertEqual(cardFrames().count, 1)
    }

    // ---- Iteration 5: dark mode
    func test30_darkModeAppliesAndPersists() {
        launch()
        tap("tab-settings")
        tap("appearance-row")
        tap("appearance-row")
        XCTAssertTrue(textOf("appearance-row").contains("Dark") || textFrame("Dark") != nil, "value not Dark")
        tap("tab-notes")
        let bg = luma(CGRect(x: 4, y: 150, width: 10, height: 300))
        XCTAssertLessThan(bg, 30, "background not dark (luma \(bg))")
        let card = cardFrames().first ?? .zero
        let c = luma(card.insetBy(dx: 4, dy: 4))
        XCTAssertLessThan(c, 80, "cards not dark (luma \(c))")
        relaunch()
        XCTAssertLessThan(luma(CGRect(x: 4, y: 150, width: 10, height: 300)), 30, "dark mode lost after relaunch")
    }

    func test31_editorFollowsDarkMode() {
        launch()
        tap("tab-settings")
        tap("appearance-row")
        tap("appearance-row")
        tap("tab-notes")
        openCard(titled: seedTitles[0])
        tap("mode-edit")
        let f = el("editor-input").frame
        let l = luma(CGRect(x: f.minX + 4, y: f.maxY - 60, width: f.width - 8, height: 40))
        XCTAssertLessThan(l, 60, "editor not dark (luma \(l))")
    }

    // ---- Iteration 6: share
    func test32_shareSheetOpens() {
        launch()
        openCard(titled: "Ideas")
        tap("share-button")
        let sheet = app.otherElements["ActivityListView"]
        let copy = app.descendants(matching: .any).matching(NSPredicate(format: "label == 'Copy'")).firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 6) || copy.waitForExistence(timeout: 2), "share sheet not shown")
    }
}

// MARK: - Monkey: random taps, counts crashes

struct SplitMix: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

final class Monkey: Base {
    func testMonkey() {
        // System sheets (share sheet, keyboard) live in other processes; a failed accessibility query
        // there must not end the run — record it and keep tapping.
        continueAfterFailure = true
        let taps = Int(env["MONKEY_TAPS"] ?? "1000") ?? 1000
        var rng = SplitMix(state: UInt64(env["SEED"] ?? "42") ?? 42)
        launch()
        let size = app.frame.size
        var crashes = 0, typed = 0
        var events: [String] = []
        let start = Date()
        for i in 0..<taps {
            if app.state != .runningForeground {
                crashes += 1
                events.append("tap \(i): app state \(app.state.rawValue) — relaunching")
                app.launch()
            }
            let x = Double.random(in: 4..<(size.width - 4), using: &rng)
            let y = Double.random(in: 64..<(size.height - 20), using: &rng)
            tapPoint(x, y)
            if i % 500 == 499 { save(i + 1) }
            // "typing" = tapping a random key on the on-screen keyboard (works without accessibility focus)
            if keyboardUp && Double.random(in: 0..<1, using: &rng) < 0.2 {
                let keys = app.keyboards.firstMatch.keys.allElementsBoundByIndex.filter { $0.isHittable }
                if !keys.isEmpty {
                    let k = keys[Int.random(in: 0..<keys.count, using: &rng)]
                    tapPoint(k.frame.midX, k.frame.midY)
                    typed += 1
                }
            }
        }
        if app.state != .runningForeground { crashes += 1; events.append("end: app state \(app.state.rawValue)") }
        save(taps)
        func save(_ done: Int) {
            let result: [String: Any] = [
                "bundle": bundleId, "taps": done, "planned": taps, "typed": typed, "crashes": crashes,
                "seconds": Int(Date().timeIntervalSince(start)), "events": events,
            ]
            let data = try! JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            try? data.write(to: URL(fileURLWithPath: "\(outDir)/monkey.json"))
        }
    }
}

// MARK: - Scripted walkthrough used for the videos

final class Demo: Base {
    func testDemo() {
        launch()
        settle(1.5)
        // browse + preview/edit
        openCard(titled: seedTitles[0])
        settle(1.5)
        tap("mode-edit")
        settle(1.2)
        tap("mode-preview")
        tap("back-button")
        // tags + search
        tap("tag-filter-work")
        settle(1.0)
        tap("tag-filter-all")
        tap("search-input")
        type("grocer")
        settle(1.0)
        deleteChars(6)
        // checklist
        openCard(titled: "Grocery list")
        for id in ["task-1", "task-2"] {
            let t = el(id)
            if wait(t, 3) { tapPoint(t.frame.midX, t.frame.midY); settle(0.8) }
        }
        tap("back-button")
        settle(1.0)
        // new note with markdown
        tap("add-note-button")
        settle(0.6)
        focusEditorEnd()
        deleteChars(12)
        type("# Weekend plans\n\n- [ ] Hike the ridge\n- [ ] Try the *new* cafe\n\n> Leave by `8:00` #trip")
        settle(1.0)
        tap("mode-preview")
        settle(1.5)
        tap("star-button")
        // share sheet
        tap("share-button")
        settle(2.0)
        let close = app.buttons.matching(NSPredicate(format: "label IN {'Close', 'Cancel'}")).firstMatch
        if close.waitForExistence(timeout: 2) { close.tap() } else { app.swipeDown() }
        settle(1.0)
        tap("back-button")
        settle(1.0)
        // delete + undo
        openCard(titled: "Ideas")
        tap("delete-button")
        settle(1.2)
        tap("undo-button")
        settle(1.0)
        // starred, settings, dark mode
        tap("tab-starred")
        settle(1.2)
        tap("tab-settings")
        tap("sort-row")
        tap("tab-notes")
        settle(1.2)
        tap("tab-settings")
        tap("sort-row")
        tap("appearance-row")
        tap("appearance-row")
        settle(1.0)
        tap("tab-notes")
        settle(1.5)
        openCard(titled: "Grocery list")
        settle(1.5)
        tap("back-button")
        tap("tab-settings")
        tap("appearance-row")
        tap("reset-button")
        tap("tab-notes")
        settle(1.5)
    }
}

// MARK: - Standard launch metric (process start -> first frame), as Xcode's launch-performance tests measure it

final class LaunchPerf: Base {
    func testLaunchMetric() {
        let options = XCTMeasureOptions()
        options.iterationCount = 10
        measure(metrics: [XCTApplicationLaunchMetric()], options: options) {
            app.launch()
        }
        app.terminate()
    }

    func testLaunchToResponsive() {
        let options = XCTMeasureOptions()
        options.iterationCount = 10
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)], options: options) {
            app.launch()
        }
        app.terminate()
    }
}
