// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP
import SwiftUI
import XCTest
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.assertIsDisplayed

final class ActionSymbolTests: XCSnapshotTestCase {
    func testUpArrowRendersItsRequestedForegroundInsteadOfAMissingIcon() throws {
        let painted = try render(view: Image(systemName: "arrow.up")
            .font(.system(size: 24))
            .foregroundColor(Color(red: 0, green: 1, blue: 0))
            .frame(width: 32, height: 32)
            .background(Color.black))
        composeRule.onNodeWithContentDescription("missing icon").assertDoesNotExist()
        composeRule.onNodeWithContentDescription("arrow.up").assertIsDisplayed()
        XCTAssertTrue(painted.pixmap.contains("00FF00"), "The actual glyph must use the caller's foreground color")
    }
}
#endif
