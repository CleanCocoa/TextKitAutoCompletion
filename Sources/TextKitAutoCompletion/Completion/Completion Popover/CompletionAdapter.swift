//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

@MainActor
class CompletionAdapter: NSObject {
    fileprivate let proxy: TextViewProxy
    fileprivate var originalString: String
    fileprivate var partialWordRange: NSRange

    init(
        textView: NSTextView,
        originalString: String,
        partialWordRange: NSRange,
        willProxyInvocation proxyInvocationCallback: @escaping TextViewProxy.ProxyInvocationCallback = { _, _, _, _ in /* no op */ }
    ) {
        self.proxy = TextViewProxy(textView: textView, willProxyInvocation: proxyInvocationCallback)
        self.originalString = originalString
        self.partialWordRange = partialWordRange
    }

    convenience init(
        textView: NSTextView,
        willProxyInvocation proxyInvocationCallback: @escaping TextViewProxy.ProxyInvocationCallback = { _, _, _, _ in /* no op */ }
    ) {
        guard let textStorage = textView.textStorage else { preconditionFailure("NSTextView should have a text storage") }
        self.init(
            textView: textView,
            originalString: textStorage.mutableString.substring(with: textView.rangeForUserCompletion),
            partialWordRange: textView.rangeForUserCompletion,
            willProxyInvocation: proxyInvocationCallback
        )
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
