//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

/// Text view with a configurable ``strategy`` to get to ``rangeForUserCompletion``.
///
/// Defaults to the system standard ``TextViewDefaultRangeStrategy`` so you can subclass in your app and not worry about accidentally changing behavior.
open class RangeConfigurableTextView: NSTextView {
    /// Strategy to compute ``rangeForUserCompletion``.
    public var strategy: any RangeForUserCompletionStrategy = TextViewDefaultRangeStrategy()

    open override var rangeForUserCompletion: NSRange {
        if strategy is TextViewDefaultRangeStrategy {
            // TextViewDefaultRangeStrategy uses NSTextView.rangeForUserCompletion, so we would create a cycle unless we break out to `super` here.
            return super.rangeForUserCompletion
        } else {
            return strategy.rangeForUserCompletion(textView: self)
        }
    }
}
