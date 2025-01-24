//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

/// Default built-in TextKit strategy to obtain the range for user completion.
public struct TextViewDefaultRangeStrategy: RangeForUserCompletionStrategy {
    public init() {}

    @inlinable
    public func rangeForUserCompletion(textView: NSTextView) -> NSRange {
        return textView.rangeForUserCompletion
    }
}
