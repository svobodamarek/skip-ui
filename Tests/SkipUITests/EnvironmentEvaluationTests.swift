// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP
import SwiftUI
import XCTest
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.test.junit4.createComposeRule

final class EnvironmentEvaluationTests: SkipUITestCase {
    // SKIP INSERT: @get:org.junit.Rule val composeRule = createComposeRule()

    func testReturningEnvironmentEvaluationSettlesAfterParentChange() {
        let revision = mutableStateOf(0)
        let visits = java.util.concurrent.atomic.AtomicInteger(0)
        let observed = java.util.concurrent.atomic.AtomicInteger(-1)
        composeRule.setContent {
            let current = revision.value
            // Bound the failing implementation so it cannot hang the runner.
            if visits.incrementAndGet() <= 12 {
                let support = EnvironmentSupport(valueHolder: 0)
                let value = EnvironmentValues.shared.setValuesWithReturn {
                    $0.setBridged(key: "test-returning-evaluation", value: support)
                    return ComposeResult.ok
                } in: {
                    _ = EnvironmentValues.shared.bridged(key: "test-returning-evaluation")
                    return current
                }
                observed.set(value)
                Text("Revision \(value)").Compose()
            }
        }
        composeRule.runOnIdle { revision.value = 1 }
        composeRule.waitForIdle()
        XCTAssertEqual(observed.get(), 1)
        XCTAssertEqual(visits.get(), 2)
    }

    func testOrdinaryEnvironmentContentSettlesAfterParentChange() {
        let revision = mutableStateOf(0)
        let visits = java.util.concurrent.atomic.AtomicInteger(0)
        let observed = java.util.concurrent.atomic.AtomicInteger(-1)
        composeRule.setContent {
            let current = revision.value
            if visits.incrementAndGet() <= 12 {
                let support = EnvironmentSupport(valueHolder: 0)
                EnvironmentValues.shared.setValues {
                    $0.setBridged(key: "test-ordinary-evaluation", value: support)
                    return ComposeResult.ok
                } in: {
                    _ = EnvironmentValues.shared.bridged(key: "test-ordinary-evaluation")
                    observed.set(current)
                    Text("Revision \(current)").Compose()
                }
            }
        }
        composeRule.runOnIdle { revision.value = 1 }
        composeRule.waitForIdle()
        XCTAssertEqual(observed.get(), 1)
        XCTAssertEqual(visits.get(), 2)
    }

    func testReturningEvaluationRetainsContentStateObservation() {
        let revision = mutableStateOf(0)
        let visits = java.util.concurrent.atomic.AtomicInteger(0)
        let observed = java.util.concurrent.atomic.AtomicInteger(-1)
        composeRule.setContent {
            if visits.incrementAndGet() <= 12 {
                let support = EnvironmentSupport(valueHolder: 0)
                let value = EnvironmentValues.shared.setValuesWithReturn {
                    $0.setBridged(key: "test-returning-content-state", value: support)
                    return ComposeResult.ok
                } in: {
                    _ = EnvironmentValues.shared.bridged(key: "test-returning-content-state")
                    return revision.value
                }
                observed.set(value)
                Text("Revision \(value)").Compose()
            }
        }
        composeRule.runOnIdle { revision.value = 1 }
        composeRule.waitForIdle()
        XCTAssertEqual(observed.get(), 1)
        XCTAssertEqual(visits.get(), 2)
    }

    func testReturningEvaluationRestoresNestedEnvironmentScopes() {
        let revision = mutableStateOf(0)
        let visits = java.util.concurrent.atomic.AtomicInteger(0)
        let valid = java.util.concurrent.atomic.AtomicBoolean(true)
        composeRule.setContent {
            let current = revision.value
            if visits.incrementAndGet() <= 12 {
                let outer = EnvironmentSupport(valueHolder: 0)
                let inner = EnvironmentSupport(valueHolder: 0)
                let matched = EnvironmentValues.shared.setValuesWithReturn {
                    $0.setBridged(key: "test-returning-scope", value: outer)
                    return ComposeResult.ok
                } in: {
                    let before = EnvironmentValues.shared.bridged(key: "test-returning-scope") === outer
                    let nested = EnvironmentValues.shared.setValuesWithReturn {
                        $0.setBridged(key: "test-returning-scope", value: inner)
                        return ComposeResult.ok
                    } in: { EnvironmentValues.shared.bridged(key: "test-returning-scope") === inner }
                    let after = EnvironmentValues.shared.bridged(key: "test-returning-scope") === outer
                    return before && nested && after
                }
                let restored = EnvironmentValues.shared.bridged(key: "test-returning-scope") == nil
                if !matched || !restored { valid.set(false) }
                Text("Revision \(current)").Compose()
            }
        }
        composeRule.runOnIdle { revision.value = 1 }
        composeRule.waitForIdle()
        XCTAssertTrue(valid.get())
        XCTAssertEqual(visits.get(), 2)
    }
}
#endif
