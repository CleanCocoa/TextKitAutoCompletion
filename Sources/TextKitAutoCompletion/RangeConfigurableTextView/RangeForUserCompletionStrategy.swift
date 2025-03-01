//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

/// Strategy to get to the range for user completion in a text view.
///
/// ## Implementation Notes
/// In ``rangeForUserCompletion(textView:)``, you should not rely on `textView.rangeForUserCompletion` and modify it, because that's very likely the caller of this function and would produce a cycle.
public protocol RangeForUserCompletionStrategy {
    @MainActor
    func rangeForUserCompletion(textView: NSTextView) -> NSRange
}
