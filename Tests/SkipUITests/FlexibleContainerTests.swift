// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP
import SwiftUI
import XCTest
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createComposeRule

final class FlexibleContainerTests: SkipUITestCase {
    // SKIP INSERT: @get:org.junit.Rule val composeRule = createComposeRule()

    func testFlexibleHooksKeepIdentityWhenContentRecomposes() {
        let revision = mutableStateOf(0)
        let visits = java.util.concurrent.atomic.AtomicInteger(0)
        let widths = java.util.IdentityHashMap<Any, Bool>()
        let heights = java.util.IdentityHashMap<Any, Bool>()
        composeRule.setContent {
            let current = revision.value
            // Change an inert fixed-width input to execute the container body,
            // not only its independently restarted child content.
            ComposeFlexibleContainer(fixedWidth: true, flexibleWidthMin: Float(current + 1), fixedHeight: true) { _ in
                // Stop reading after a bounded number of visits so the failing
                // implementation can settle instead of hanging the test runner.
                if visits.incrementAndGet() <= 16 {
                    if let width = EnvironmentValues.shared._flexibleWidth { widths.put(width, true) }
                    if let height = EnvironmentValues.shared._flexibleHeight { heights.put(height, true) }
                    Text("Revision \(current)").Compose()
                }
            }
        }
        composeRule.runOnIdle { revision.value = 1 }
        composeRule.waitForIdle()
        XCTAssertGreaterThan(visits.get(), 1)
        XCTAssertEqual(widths.size, 1)
        XCTAssertEqual(heights.size, 1)
    }

    func testFlexibleHooksReadTheCurrentDirectionalModifiers() {
        let revision = mutableStateOf(0)
        let visits = java.util.concurrent.atomic.AtomicInteger(0)
        let widths = java.util.ArrayList<Int>()
        let heights = java.util.ArrayList<Int>()
        composeRule.setContent {
            let current = revision.value
            let widthModifier: (Float?, Float?, Float?) -> Modifier = remember(current) {
                { _, _, _ in widths.add(current); return Modifier }
            }
            let heightModifier: (Float?, Float?, Float?) -> Modifier = remember(current) {
                { _, _, _ in heights.add(current); return Modifier }
            }
            // Change an inert fixed-width input to execute the container body,
            // not only its independently restarted child content.
            ComposeFlexibleContainer(fixedWidth: true, flexibleWidthMin: Float(current + 1), fixedHeight: true) { _ in
                if visits.incrementAndGet() <= 24 {
                    EnvironmentValues.shared.setValues {
                        $0.set_flexibleWidthModifier(widthModifier)
                        $0.set_flexibleHeightModifier(heightModifier)
                        return ComposeResult.ok
                    } in: {
                        _ = EnvironmentValues.shared._flexibleWidth?(nil, nil, Float.flexibleFill)
                        _ = EnvironmentValues.shared._flexibleHeight?(nil, nil, Float.flexibleFill)
                        Text("Revision \(current)").Compose()
                    }
                }
            }
        }
        composeRule.runOnIdle { visits.set(0); revision.value = 1 }
        composeRule.waitForIdle()
        XCTAssertTrue(widths.contains(0)); XCTAssertTrue(heights.contains(0))
        XCTAssertEqual(widths.lastOrNull(), 1); XCTAssertEqual(heights.lastOrNull(), 1)
    }
}
#endif
