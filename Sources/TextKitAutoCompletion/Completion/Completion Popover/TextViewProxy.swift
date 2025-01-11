//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

/// Proxies messages passed down the responder chain to its ``textView`` and informs ``proxyInvocationCallback`` for each proxied call.
///
/// Introduced to forward main menu item validation and usage from the completion popover, which becomes key window, to the text view that runs the completion session. The callback then will be used to distinguish menu item validation (via `responds(to:)`) from execution (via one of the `perform` overloads). During execution, we want to automatically cancel the completion session.
final class TextViewProxy: NSObject, Sendable {
    typealias ProxyInvocationCallback = @Sendable (_ receiver: AnyObject, _ selector: Selector, _ arg1: Any?, _ arg2: Any?) -> Void

    let textView: NSTextView
    let proxyInvocationCallback: ProxyInvocationCallback

    init(
        textView: NSTextView,
        willProxyInvocation proxyInvocationCallback: @escaping ProxyInvocationCallback = { _, _, _, _ in /* no op */ }
    ) {
        self.textView = textView
        self.proxyInvocationCallback = proxyInvocationCallback
    }

    // These method decorations are added just so that we don't have to reach into this proxy object to control its `textView`.

    @MainActor @inlinable @inline(__always)
    func insertText(_ insertString: Any) {
        textView.insertText(insertString)
    }

    @MainActor @inlinable @inline(__always)
    func doCommand(by selector: Selector) {
        textView.doCommand(by: selector)
    }

    // These method overrides are sufficient to behave like the `textView` and make it respond.

    override func responds(to aSelector: Selector!) -> Bool {
        textView.responds(to: aSelector)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return textView
    }

    // These `perform` overrides proxy to `textView` and notify the callback.

    override func perform(_ selector: Selector!) -> Unmanaged<AnyObject>! {
        proxyInvocationCallback(textView, selector, nil, nil)
        return textView.perform(selector)
    }

    override func perform(_ selector: Selector!, with object: Any!) -> Unmanaged<AnyObject>! {
        proxyInvocationCallback(textView, selector, object, nil)
        return textView.perform(selector, with: object)
    }

    override func perform(_ selector: Selector!, with object1: Any!, with object2: Any!) -> Unmanaged<AnyObject>! {
        proxyInvocationCallback(textView, selector, object1, object2)
        return textView.perform(selector, with: object1, with: object2)
    }
}
