import Foundation

enum SeedNotes {
    private static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = h; c.minute = min
        return Calendar(identifier: .gregorian).date(from: c) ?? Date()
    }

    static var all: [Note] {
        [
            Note(id: "welcome", body: """
            # Welcome to Markdown Notes

            Write in **Markdown** and switch to *Preview* to see it rendered.

            ## What works

            - Headings, **bold** and *italic*
            - Inline `code` and code blocks
            - Bullet and numbered lists

            > Notes are saved on your device automatically.

            ```
            const hello = "world";
            ```

            #welcome
            """, starred: true, updatedAt: date(2026, 10, 1, 9, 30)),
            Note(id: "groceries", body: """
            # Grocery list

            - [x] Oat milk
            - [ ] Sourdough bread
            - [ ] Blueberries
            - [x] Dark chocolate

            #home #shopping
            """, starred: false, updatedAt: date(2026, 9, 30, 18, 5)),
            Note(id: "meeting", body: """
            # Meeting notes

            ## Q4 planning

            1. Ship the beta by **Nov 15**
            2. Hire one more designer
            3. Review analytics weekly

            #work
            """, starred: true, updatedAt: date(2026, 9, 28, 14, 0)),
            Note(id: "ideas", body: """
            # Ideas

            Build a tiny habit tracker. Maybe *one tap* per day, no accounts, no sync. #ideas
            """, starred: false, updatedAt: date(2026, 9, 25, 8, 15)),
        ]
    }
}
