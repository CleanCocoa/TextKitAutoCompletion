//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

/// Text view with a configurable ``strategy`` to get to ``rangeForUserCompletion``.
///
/// Defaults to the system standard ``TextViewDefaultRangeStrategy`` so you can subclass in your app and not worry about accidentally changing behavior.
open class RangeConfigurableTextView: NSTextView {
    /// Strategy to compute ``rangeForUserCompletion``.
    public var strategy: any RangeForUserCompletionStrategy = TextViewDefaultRangeStrategy()

    open override var rangeForUserCompletion: NSRange {
        return strategy.rangeForUserCompletion(textView: self)
    }
}
