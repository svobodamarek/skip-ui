// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP
import SwiftUI
import XCTest
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick

final class LazyScrollTargetTests: SkipUITestCase {
    // SKIP INSERT: @get:org.junit.Rule val composeRule = createComposeRule()

    func testTailInsideLazyContentCanBeReachedByScrollViewReader() {
        composeRule.setContent { fixture(tailInside: true).Compose() }
        composeRule.onNodeWithText("Row 0").assertIsDisplayed()
        composeRule.onNodeWithText("Latest").performClick()
        composeRule.onNodeWithText("Row 29").assertIsDisplayed()
    }

    func testSiblingTailIsNotARegisteredLazyScrollTarget() {
        composeRule.setContent { fixture(tailInside: false).Compose() }
        composeRule.onNodeWithText("Row 0").assertIsDisplayed()
        composeRule.onNodeWithText("Latest").performClick()
        composeRule.onNodeWithText("Row 0").assertIsDisplayed()
        composeRule.onNodeWithText("Row 29").assertDoesNotExist()
    }

    func testProxyCapturedBeforeLazyRegistrationUsesTheMountedReader() {
        let captured = java.util.concurrent.atomic.AtomicReference<ScrollViewProxy?>(nil)
        composeRule.setContent {
            fixture(tailInside: true, captured: { proxy in
                _ = captured.compareAndSet(nil, proxy)
            }).Compose()
        }
        composeRule.onNodeWithText("Row 0").assertIsDisplayed()
        composeRule.runOnIdle {
            let proxy: ScrollViewProxy = captured.get()!
            proxy.scrollTo("tail", anchor: UnitPoint.bottom)
        }
        composeRule.waitForIdle()
        composeRule.onNodeWithText("Row 29").assertIsDisplayed()
    }

    func testInitialTaskCanReachTailWithoutAnotherUserAction() {
        composeRule.setContent { fixture(tailInside: true, scrollOnMount: true).Compose() }
        composeRule.waitForIdle()
        composeRule.onNodeWithText("Row 29").assertIsDisplayed()
    }

    func testPendingRequestIsLatestOnlyAndRetiredReaderCannotResumeIt() {
        let reader = ScrollViewReaderState()
        var received: [String] = []
        reader.scrollTo("superseded")
        reader.scrollTo("latest")
        reader.update(ScrollToIDAction(key: nil, action: { _ in received.append("invalid") }))
        XCTAssertTrue(received.isEmpty)
        reader.update(ScrollToIDAction(key: "first-list", action: { id in received.append("first:" + (id as! String)) }))
        XCTAssertEqual(received, ["first:latest"])
        reader.update(ScrollToIDAction(key: "replacement-list", action: { id in received.append("replacement:" + (id as! String)) }))
        reader.scrollTo("current")
        XCTAssertEqual(received, ["first:latest", "replacement:current"])
        reader.update(ScrollToIDAction(key: nil, action: { _ in received.append("invalid") }))
        reader.scrollTo("discarded")
        reader.retire()
        reader.update(ScrollToIDAction(key: "late-list", action: { _ in received.append("resurrected") }))
        reader.scrollTo("stale-proxy")
        XCTAssertEqual(received, ["first:latest", "replacement:current"])
    }

    private func fixture(tailInside: Bool, captured: ((ScrollViewProxy) -> Void)? = nil,
                         scrollOnMount: Bool = false) -> some View {
        ScrollViewReader { proxy in
            captured?(proxy)
            return VStack {
                Button("Latest") { proxy.scrollTo("tail", anchor: .bottom) }
                ScrollView {
                    VStack(spacing: 0) {
                        LazyVStack(spacing: 2) {
                            ForEach(0..<30, id: \.self) { index in
                                Text("Row \(index)").frame(height: 40).id(index)
                            }
                            if tailInside { Color.clear.frame(height: 1).id("tail") }
                        }
                        if !tailInside { Color.clear.frame(height: 1).id("tail") }
                    }
                }.frame(width: 320, height: 220)
                    .task { if scrollOnMount { proxy.scrollTo("tail", anchor: .bottom) } }
            }
        }
    }
}
#endif
