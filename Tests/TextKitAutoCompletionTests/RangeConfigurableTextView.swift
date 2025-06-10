//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextKitAutoCompletion

class RangeConfigurableTextView<Strategy>: NSTextView
where Strategy: RangeForUserCompletionStrategy {
    var strategy: Strategy

    required init(strategy: Strategy) {
        self.strategy = strategy
        let textContainer = NSTextContainer(containerSize: .zero)
        super.init(frame: .zero, textContainer: textContainer)
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    @available(*, unavailable)
    override init(frame frameRect: NSRect) { fatalError() }

    @available(*, unavailable)
    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) { fatalError() }

    open override var rangeForUserCompletion: NSRange {
        if strategy is TextViewDefaultRangeStrategy {
            // TextViewDefaultRangeStrategy uses NSTextView.rangeForUserCompletion, so we would create a cycle unless we break out to `super` here.
            return super.rangeForUserCompletion
        } else {
            switch strategy.rangeForUserCompletion(textView: self) {
            case .range(let range): return range
            case .failure(_): return super.rangeForUserCompletion
            }
        }
    }
}
