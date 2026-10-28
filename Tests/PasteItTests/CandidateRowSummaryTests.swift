import Testing
@testable import PasteItCore

struct CandidateRowSummaryTests {
    @Test(arguments: [
        ("short text", "short text"),
        ("first line\nsecond line", "first line…"),
        ("中文第一行\r\n第二行", "中文第一行…"),
        ("日本語\u{2028}English", "日本語…"),
        ("第一行…\n第二行", "第一行…"),
        ("\n  first line  \nsecond", "first line…"),
        ("first line\n\n", "first line"),
        (" \t\r\n", "")
    ])
    func firstLineMarksHiddenContent(input: String, expected: String) {
        #expect(CandidateRowSummary.firstLine(input) == expected)
    }

    @Test func boundsLongLabelsWithoutSplittingGraphemes() {
        let family = "👨‍👩‍👧‍👦"
        #expect(CandidateRowSummary.firstLine("A" + family + "B", limit: 2) == "A" + family + "…")
        #expect(CandidateRowSummary.firstLine("abcdef", limit: 4) == "abcd…")
        #expect(CandidateRowSummary.firstLine("abcdef", limit: 6) == "abcdef")
        #expect(!CandidateRowSummary.firstLine(String(repeating: "长", count: 600)).contains("\n"))
        #expect(CandidateRowSummary.firstLine(String(repeating: "长", count: 600)).count == 513)
    }
}
