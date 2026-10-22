// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !SKIP_BRIDGE && SKIP
/// Imperative proxy lifetime, owned by one mounted ScrollViewReader. This is
/// deliberately not snapshot state: commands must not invalidate composition.
final class ScrollViewReaderState {
    private var active = true
    private var action: ScrollToIDAction?
    private var pendingID: Any?

    func scrollTo(_ id: Any) {
        guard active else { return }
        guard let action else {
            // Before lazy registration, only the latest request is meaningful.
            pendingID = id
            return
        }
        action.action(id)
    }

    func update(_ action: ScrollToIDAction) {
        guard active else { return }
        guard action.key != nil else {
            self.action = nil
            return
        }
        self.action = action
        if let id = pendingID {
            pendingID = nil
            action.action(id)
        }
    }

    func retire() {
        active = false
        action = nil
        pendingID = nil
    }
}
#endif
