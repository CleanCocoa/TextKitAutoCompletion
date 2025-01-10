//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

@MainActor
class CompletionAdapter {
    let adaptee: NSTextView
    fileprivate var originalString: String
    fileprivate var partialWordRange: NSRange

    init(
        adaptee: NSTextView,
        originalString: String,
        partialWordRange: NSRange
    ) {
        self.adaptee = adaptee
        self.originalString = originalString
        self.partialWordRange = partialWordRange
    }

    @MainActor
    func cancelCompletion() {
        adaptee.insertCompletion(
            originalString,
            forPartialWordRange: partialWordRange,
            movement: .cancel,
            isFinal: true
        )
    }

    @MainActor
    func finishCompletion(text: String) {
        adaptee.insertCompletion(
            text,
            forPartialWordRange: partialWordRange,
            movement: .return,
            isFinal: true
        )
    }

    @MainActor
    func suggestCompletion(text: String) {
        adaptee.insertCompletion(
            text,
            forPartialWordRange: partialWordRange,
            // TextKit's completion system supports movement to change the selected completion candidate, or ends when using a non-movement key. We allow typing to refine suggestions, though.
            movement: .other,
            isFinal: false
        )
    }
}

extension CompletionAdapter {
    convenience init(textView: NSTextView) {
        guard let textStorage = textView.textStorage else { preconditionFailure("NSTextView should have a text storage") }
        self.init(
            adaptee: textView,
            originalString: textStorage.mutableString.substring(with: textView.rangeForUserCompletion),
            partialWordRange: textView.rangeForUserCompletion
        )
    }
}
