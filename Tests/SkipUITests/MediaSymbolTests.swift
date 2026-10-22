// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP
import SwiftUI
import XCTest
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription

final class MediaSymbolTests: SkipUITestCase {
    // SKIP INSERT: @get:org.junit.Rule val composeRule = createComposeRule()

    func testSharedMediaSymbolsResolveToDrawableImages() {
        composeRule.setContent {
            VStack {
                Image(systemName: "photo.on.rectangle")
                Image(systemName: "photo.on.rectangle.angled")
            }.Compose()
        }
        composeRule.onNodeWithContentDescription("photo.on.rectangle").assertExists()
        composeRule.onNodeWithContentDescription("photo.on.rectangle.angled").assertExists()
        composeRule.onNodeWithContentDescription("missing icon").assertDoesNotExist()
    }
}
#endif
