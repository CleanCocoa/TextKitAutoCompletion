//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextViewProxy

@MainActor
class CompletionAdapter: NSObject {
    fileprivate let proxy: TextViewProxy
    weak var proxyDelegate: TextViewProxyDelegate? {
        get { proxy.delegate }
        set { proxy.delegate = newValue }
    }

    /// The string that will be left/restored when completion is aborted.
    ///
    /// Use ``update(originalString:partialWordRange:)`` to reflect changes from typing during the autocompletion session.
    fileprivate(set) var originalString: String

    /// The string that will be left/restored when completion is aborted.
    ///
    /// Use ``update(originalString:partialWordRange:)`` to reflect changes from typing during the autocompletion session.
    fileprivate(set) var partialWordRange: NSRange

    init(
        textView: NSTextView,
        originalString: String,
        partialWordRange: NSRange
    ) {
        self.proxy = TextViewProxy(textView: textView)
        self.originalString = originalString
        self.partialWordRange = partialWordRange
    }

    convenience init(
        textView: NSTextView
    ) {
        guard let textStorage = textView.textStorage else { preconditionFailure("NSTextView should have a text storage") }
        self.init(
            textView: textView,
            originalString: textStorage.mutableString.substring(with: textView.rangeForUserCompletion),
            partialWordRange: textView.rangeForUserCompletion
        )
    }

    /// Update what's considered the `originalString` (the string that'll be left when aborting completion) and the `partialWordRange` (the range that represents this original string to highlight the rest as a completion suggestion).
    func update(originalString: String, partialWordRange: NSRange) {
        self.originalString = originalString
        self.partialWordRange = partialWordRange
        print(partialWordRange)
    }
}

// MARK: Decorating the private proxy

extension CompletionAdapter {
    func insertText(_ insertString: Any) {
        proxy.insertText(insertString)
    }

    func doCommand(by selector: Selector) {
        proxy.doCommand(by: selector)
    }

    override func responds(to aSelector: Selector!) -> Bool {
        proxy.responds(to: aSelector)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return proxy
    }
}

// MARK: - Completion API

extension CompletionAdapter {
    @MainActor
    func cancelCompletion() {
        proxy.textView.insertCompletion(
            originalString,
            forPartialWordRange: partialWordRange,
            movement: .cancel,
            isFinal: true
        )
    }

    @MainActor
    func finishCompletion(text: String) {
        proxy.textView.insertCompletion(
            text,
            forPartialWordRange: partialWordRange,
            movement: .return,
            isFinal: true
        )
    }

    @MainActor
    func suggestCompletion(text: String) {
        proxy.textView.insertCompletion(
            text,
            forPartialWordRange: partialWordRange,
            // TextKit's completion system supports movement to change the selected completion candidate, or ends when using a non-movement key. We allow typing to refine suggestions, though.
            movement: .other,
            isFinal: false
        )
    }
}
