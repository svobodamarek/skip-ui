// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !SKIP_BRIDGE

/// Support for bridged`SwiftUI.@Environment`.
///
/// The Compose side manages object lifecycles, so we hold references to the native value.
/// Environment values are not necessarily bridged or bridgable, so we use an opaque pointer.
/// This support object is placed in the Compose environment.
// SKIP @bridge
public final class EnvironmentSupport {
    /// Supply a Swift pointer to an object that holds the environment value and a block to release the object on finalize.
    // SKIP @bridge
    public init(valueHolder: Int64) {
        self.valueHolder = valueHolder
        self.builtinValue = nil
        self.comparison = nil
    }

    /// Optional native equality token for custom environment values. The
    /// opaque holder still owns the value read by native property wrappers.
    // SKIP @bridge
    public init(valueHolder: Int64, comparison: Any?) {
        self.valueHolder = valueHolder
        self.builtinValue = nil
        self.comparison = comparison
    }

    // SKIP @bridge
    public init(builtinValue: Any?) {
        self.builtinValue = builtinValue
        self.valueHolder = Int64(0)
        self.comparison = nil
    }

    #if SKIP
    deinit {
        if valueHolder != Int64(0) {
            valueHolder = Swift_release(valueHolder)
        }
    }

    /// - Seealso `SkipSwiftUI.Environment`
    // SKIP EXTERN
    private func Swift_release(Swift_valueHolder: Int64) -> Int64

    public override func equals(other: Any?) -> Bool {
        guard let other = other as? EnvironmentSupport else { return false }
        guard let comparison, let otherComparison = other.comparison else {
            return self === other
        }
        return comparison == otherComparison
    }

    public override func hashCode() -> Int {
        return comparison?.hashCode() ?? System.identityHashCode(self)
    }
    #endif


    // SKIP @bridge
    public private(set) var valueHolder: Int64

    // SKIP @bridge
    public let builtinValue: Any?

    private let comparison: Any?
}

#endif
