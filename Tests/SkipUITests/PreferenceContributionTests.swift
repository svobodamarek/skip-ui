// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP
import SwiftUI
import XCTest
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.snapshots.Snapshot
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText

final class PreferenceContributionTests: SkipUITestCase {
    // SKIP INSERT: @get:org.junit.Rule val composeRule = createComposeRule()

    func testCollectorRefreshDoesNotReadStateItWritesDuringComposition() {
        let revision = mutableStateOf(0)
        let backwardWrites = java.util.concurrent.atomic.AtomicInteger(0)
        let preference = mutableStateOf(Preference<Any?>(key: "contribution-refresh", initialValue: nil,
            reducer: { _, next in next }))
        composeRule.setContent {
            let currentRevision = revision.value
            // Deliver one new collector per external revision. It then stays
            // stable so the failing control cannot keep the test runner busy.
            let collector = remember(currentRevision) {
                PreferenceCollector<Any?>(key: "contribution-refresh", state: preference)
            }
            PreferenceValues.shared.collectPreferences([collector]) {
                let reads = java.util.IdentityHashMap<Any, Bool>()
                let writes = java.util.IdentityHashMap<Any, Bool>()
                let snapshot = Snapshot.takeMutableSnapshot(readObserver: { reads.put($0, true) },
                    writeObserver: { writes.put($0, true) })
                snapshot.enter {
                    PreferenceValues.shared.contribute(context: ComposeContext(), key: "contribution-refresh",
                        value: "Value \(currentRevision)")
                }
                snapshot.apply().check()
                snapshot.dispose()
                if reads.keys.any({ writes.containsKey($0) }) { backwardWrites.incrementAndGet() }
                Text("Revision \(currentRevision)").Compose()
            }
        }
        composeRule.runOnIdle { revision.value = 1 }
        composeRule.waitForIdle()
        composeRule.onNodeWithText("Revision 1").assertExists()
        XCTAssertEqual(preference.value.reduced as? String, "Value 1")
        XCTAssertEqual(backwardWrites.get(), 0)
    }

    func testLatestCollectorReceivesUpdatesAndIsRetiredOnDisposal() {
        let revision = mutableStateOf(0)
        let mounted = mutableStateOf(true)
        let first = mutableStateOf(Preference<Any?>(key: "contribution-owner", initialValue: nil,
            reducer: { _, next in next }))
        let second = mutableStateOf(Preference<Any?>(key: "contribution-owner", initialValue: nil,
            reducer: { _, next in next }))
        composeRule.setContent {
            let currentRevision = revision.value
            if mounted.value {
                let collector = remember(currentRevision) {
                    PreferenceCollector<Any?>(key: "contribution-owner", state: currentRevision == 0 ? first : second)
                }
                PreferenceValues.shared.collectPreferences([collector]) {
                    PreferenceValues.shared.contribute(context: ComposeContext(), key: "contribution-owner",
                        value: "Value \(currentRevision)")
                    Text("Mounted \(currentRevision)").Compose()
                }
            } else {
                Text("Retired").Compose()
            }
        }
        composeRule.runOnIdle { revision.value = 1 }
        composeRule.waitForIdle()
        XCTAssertEqual(second.value.reduced as? String, "Value 1")
        XCTAssertNotEqual(first.value.reduced as? String, "Value 1")
        composeRule.runOnIdle { mounted.value = false }
        composeRule.waitForIdle()
        composeRule.onNodeWithText("Retired").assertExists()
        XCTAssertTrue(second.value.nodes.isEmpty)
    }
}
#endif
