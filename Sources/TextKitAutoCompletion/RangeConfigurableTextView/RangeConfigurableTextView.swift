//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

public class RangeConfigurableTextView: NSTextView {
    let strategy: any RangeForUserCompletionStrategy = WordRangeStrategy()

    public override var rangeForUserCompletion: NSRange {
        return strategy.rangeForUserCompletion(textView: self)
    }
}
