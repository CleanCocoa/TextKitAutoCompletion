//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import Omnibar

class OmnibarTextKitAutoCompletionAdapter<Adaptee>
where Adaptee: TextKitAutoCompletion {
    let adaptee: Adaptee
    fileprivate var word: String
    fileprivate var partialWordRange: NSRange

    init(
        adaptee: Adaptee,
        word: String,
        partialWordRange: NSRange
    ) {
        self.adaptee = adaptee
        self.word = word
        self.partialWordRange = partialWordRange
    }

    @MainActor
    func cancelCompletion() {
        adaptee.insertCompletion(
            word,
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

extension OmnibarTextKitAutoCompletionAdapter: OmnibarContentChangeDelegate {
    func omnibarDidCancelOperation(_ omnibar: Omnibar) {
        cancelCompletion()
    }

    func omnibar(_ omnibar: Omnibar, didChangeContent contentChange: OmnibarContentChange, method: ChangeMethod) {
        suggestCompletion(text: contentChange.string)
    }

    func omnibar(_ omnibar: Omnibar, commit text: String) {
        finishCompletion(text: text)
    }
}

extension OmnibarTextKitAutoCompletionAdapter where Adaptee: NSTextView {
    @MainActor
    convenience init(textView adaptee: Adaptee) {
        guard let textStorage = adaptee.textStorage else { preconditionFailure("NSTextView should have a text storage") }
        self.init(
            adaptee: adaptee,
            word: textStorage.mutableString.substring(with: adaptee.rangeForUserCompletion),
            partialWordRange: adaptee.rangeForUserCompletion
        )
    }
}
