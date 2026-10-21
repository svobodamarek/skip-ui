// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP
import SwiftUI
import XCTest
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText

final class AnimatedContentTests: SkipUITestCase {
    // SKIP INSERT: @get:org.junit.Rule val composeRule = createComposeRule()

    private func arguments(_ ids: kotlin.collections.List<Any>, _ views: kotlin.collections.List<Renderable>) -> AnimatedContentArguments {
        AnimatedContentArguments(renderables: views, idMap: { _ in nil }, ids: ids,
            rememberedIds: mutableSetOf<Any>(), newIds: ids, rememberedNewIds: mutableSetOf<Any>(), isBridged: true)
    }

    func testRepeatedContentRefreshKeepsOneAnimationMapKey() {
        let keys = java.util.HashMap<AnimatedContentState, Int>()
        let legacyKeys = java.util.HashMap<kotlin.collections.List<Renderable>, Int>()
        for revision in 0..<2000 {
            let current = arguments(listOf<Any>("account"), listOf<Renderable>(Text("Revision \(revision)")))
            keys.put(current.targetState, revision)
            legacyKeys.put(current.renderables, revision)
        }
        // The old list-as-state contract retains every freshly evaluated view graph.
        XCTAssertEqual(legacyKeys.size, 2000)
        XCTAssertEqual(keys.size, 1)
        XCTAssertEqual(keys.values.first(), 1999)
    }

    func testCurrentContentRefreshesAndOutgoingContentKeepsItsSnapshot() {
        let outgoing = Text("Outgoing")
        let replacement = Text("Replacement")
        let old = arguments(listOf<Any>("account"), listOf<Renderable>(outgoing))
        let refreshed = arguments(listOf<Any>("account"), listOf<Renderable>(replacement))
        XCTAssertTrue(old.targetState.content(for: refreshed)[0] === replacement)
        let otherAccount = arguments(listOf<Any>("other"), listOf<Renderable>(Text("Other account")))
        XCTAssertTrue(old.targetState.content(for: otherAccount)[0] === outgoing)
    }

    func testAnimationIdentityPreservesOrderAndMembership() {
        let a = arguments(listOf<Any>("a", "b"), listOf<Renderable>()).targetState
        let b = arguments(listOf<Any>("b", "a"), listOf<Renderable>()).targetState
        let c = arguments(listOf<Any>("a"), listOf<Renderable>()).targetState
        XCTAssertNotEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertEqual(a, arguments(listOf<Any>("a", "b"), listOf<Renderable>()).targetState)
    }

    func testBridgedVStackRefreshesContentWithUnchangedIdentity() { checkRefresh(kind: 0) }
    func testBridgedHStackRefreshesContentWithUnchangedIdentity() { checkRefresh(kind: 1) }
    func testBridgedZStackRefreshesContentWithUnchangedIdentity() { checkRefresh(kind: 2) }

    private func checkRefresh(kind: Int) {
        let revision = mutableStateOf(0)
        composeRule.setContent {
            let content = Text("Revision \(revision.value)").id("account")
            switch kind {
            case 0: VStack(alignmentKey: "center", spacing: 0.0, bridgedContent: content).Compose()
            case 1: HStack(alignmentKey: "center", spacing: 0.0, bridgedContent: content).Compose()
            default: ZStack(horizontalAlignmentKey: "center", verticalAlignmentKey: "center", bridgedContent: content).Compose()
            }
        }
        for next in 1...24 {
            composeRule.runOnIdle { revision.value = next }
            composeRule.onNodeWithText("Revision \(next)").assertExists()
        }
    }
}
#endif
