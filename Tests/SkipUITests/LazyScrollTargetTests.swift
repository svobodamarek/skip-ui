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

    private func fixture(tailInside: Bool) -> some View {
        ScrollViewReader { proxy in
            VStack {
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
            }
        }
    }
}
#endif
