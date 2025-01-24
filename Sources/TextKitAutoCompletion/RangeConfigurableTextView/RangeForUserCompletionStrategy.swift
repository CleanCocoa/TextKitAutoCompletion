//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

/// Strategy to get to the range for user completion in a text view.
public protocol RangeForUserCompletionStrategy {
    @MainActor
    func rangeForUserCompletion(textView: NSTextView) -> NSRange
}
