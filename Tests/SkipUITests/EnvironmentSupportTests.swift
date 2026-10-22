// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP
import SwiftUI
import XCTest
import androidx.compose.runtime.mutableStateOf

final class EnvironmentSupportTests: SkipUITestCase {
    func testEquivalentNativeTokensDoNotReplaceObservedEnvironmentState() {
        // Zero holders keep this JVM contract independent of native release.
        let original = EnvironmentSupport(valueHolder: 0, comparison: "dark")
        let state = mutableStateOf(original)
        let equal = EnvironmentSupport(valueHolder: 0, comparison: "dark")
        state.value = equal
        XCTAssertTrue(state.value === original)
        XCTAssertEqual(original.hashCode(), equal.hashCode())
        let changed = EnvironmentSupport(valueHolder: 0, comparison: "light")
        state.value = changed
        XCTAssertTrue(state.value === changed)
    }

    func testUnknownAndBuiltinValuesRetainExistingIdentitySemantics() {
        let unknown = EnvironmentSupport(valueHolder: 0)
        let state = mutableStateOf(unknown)
        let replacement = EnvironmentSupport(valueHolder: 0)
        state.value = replacement
        XCTAssertTrue(state.value === replacement)
        XCTAssertFalse(unknown == replacement)
        XCTAssertFalse(EnvironmentSupport(builtinValue: "dark") == EnvironmentSupport(builtinValue: "dark"))
        XCTAssertFalse(unknown == EnvironmentSupport(valueHolder: 0, comparison: "dark"))
    }
}
#endif
