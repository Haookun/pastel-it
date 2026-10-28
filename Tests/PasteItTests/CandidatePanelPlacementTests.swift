import Foundation
import Testing
@testable import PasteItCore

struct CandidatePanelPlacementTests {
    @Test func staysBelowCaretWithoutCoveringText() {
        let screen = CGRect(x: 0, y: 25, width: 1512, height: 900)
        let caret = CGRect(x: 200, y: 650, width: 0, height: 24)
        let frame = CandidatePanelPlacement.frame(anchor: caret, size: CGSize(width: 940, height: 96), visibleFrame: screen)
        #expect(frame.minX == caret.minX)
        #expect(frame.maxY == caret.minY - 6)
        #expect(screen.contains(frame))
    }

    @Test func flipsAboveAndClampsRightEdgeOnSecondaryDisplay() {
        let screen = CGRect(x: -1920, y: -400, width: 1920, height: 1080)
        let caret = CGRect(x: -20, y: -370, width: 0, height: 20)
        for height in [CGFloat(96), 360] {
            let frame = CandidatePanelPlacement.frame(anchor: caret, size: CGSize(width: 940, height: height), visibleFrame: screen)
            #expect(frame.minY == caret.maxY + 6)
            #expect(frame.maxX == screen.maxX - 8)
            #expect(screen.contains(frame))
        }
    }

    @Test func oversizedPanelAndTallExpansionStayOnScreen() {
        let screen = CGRect(x: 300, y: 1000, width: 600, height: 300)
        let frame = CandidatePanelPlacement.frame(anchor: CGRect(x: 800, y: 1150, width: 0, height: 18),
            size: CGSize(width: 940, height: 360), visibleFrame: screen)
        #expect(screen.contains(frame))
        #expect(frame.width == 584)
        #expect(frame.height == 284)
    }

    @Test func accessibilityCoordinatesUsePrimaryDisplayOriginForAllScreens() {
        #expect(CandidatePanelPlacement.appKitRect(fromAccessibility: CGRect(x: -500, y: -200, width: 0, height: 20),
            primaryScreenTop: 982) == CGRect(x: -500, y: 1162, width: 0, height: 20))
        #expect(CandidatePanelPlacement.appKitRect(fromAccessibility: CGRect(x: 200, y: 1200, width: 0, height: 20),
            primaryScreenTop: 982).minY == -238)
    }
}
