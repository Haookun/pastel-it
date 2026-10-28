import Testing
@testable import PasteItCore

struct CandidateNavigationTests {
    @Test func digitsAndLocalCommandsDoNotStealModifiedAppShortcuts() {
        #expect(CandidateKeyAction.resolve(keyCode: 18, characters: "1", modifiers: []) == .choose(0))
        #expect(CandidateKeyAction.resolve(keyCode: 23, characters: "5", modifiers: []) == .choose(4))
        #expect(CandidateKeyAction.resolve(keyCode: 22, characters: "6", modifiers: []) == .choose(5))
        #expect(CandidateKeyAction.resolve(keyCode: 18, characters: "1", modifiers: .command) == nil)
        #expect(CandidateKeyAction.resolve(keyCode: 48, characters: "\t", modifiers: []) == .nextPage)
        #expect(CandidateKeyAction.resolve(keyCode: 48, characters: "\t", modifiers: .shift) == .previousPage)
        #expect(CandidateKeyAction.resolve(keyCode: 48, characters: "\t", modifiers: .command) == nil)
        #expect(CandidateKeyAction.resolve(keyCode: 29, characters: "0", modifiers: []) == .choose(9))
        #expect(CandidateKeyAction.resolve(keyCode: 24, characters: "+", modifiers: .shift) == nil)
        #expect(CandidateKeyAction.resolve(keyCode: 36, characters: "\r", modifiers: []) == .activate)
        #expect(CandidateKeyAction.resolve(keyCode: 53, characters: "", modifiers: []) == .close)
        #expect(CandidateKeyAction.resolve(keyCode: 0, characters: "a", modifiers: []) == nil)
    }

    @Test func navigationClampsAndHandlesEmptyOrShortHistory() {
        #expect(CandidateKeyAction.movedIndex(current: nil, delta: 1, count: 0) == nil)
        #expect(CandidateKeyAction.movedIndex(current: 0, delta: -1, count: 5) == 0)
        #expect(CandidateKeyAction.movedIndex(current: 4, delta: 1, count: 5) == 4)
        #expect(CandidateKeyAction.movedIndex(current: 2, delta: 1, count: 10) == 3)
        #expect(ClipboardPresentationStyle.candidatePageSize == 10)
    }
    @Test func pagesPartitionHistoryWithoutRepeatsAndClampAfterDeletion() {
        for count in [0, 1, 9, 10, 11, 20, 23, 101] {
            let pages = CandidatePagination.pageCount(itemCount: count)
            let ranges = (0..<pages).map { CandidatePagination.range(page: $0, itemCount: count) }
            #expect(ranges.allSatisfy { $0.count <= 10 })
            #expect(ranges.flatMap { Array($0) } == Array(0..<count))
        }
        #expect(CandidatePagination.range(page: 2, itemCount: 23) == 20..<23)
        #expect(CandidatePagination.range(page: 2, itemCount: 7) == 0..<7)
        #expect(CandidatePagination.clampedPage(3, itemCount: 23) == 2)
        #expect(CandidatePagination.clampedPage(-1, itemCount: 23) == 0)
        #expect(CandidatePagination.range(page: 20, itemCount: 0).isEmpty)
    }
}
