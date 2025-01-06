//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import Omnibar

class OmnibarTextKitAutoCompletionAdapter<Adaptee>: OmnibarContentChangeDelegate
where Adaptee: TextKitAutoCompletion {
    let adaptee: Adaptee
    var word: String
    var partialWordRange: NSRange

    init(
        adaptee: TextKitAutoCompletion,
        word: String,
        partialWordRange: NSRange
    ) {
        self.adaptee = adaptee
        self.word = word
        self.partialWordRange = partialWordRange
    }

    func omnibarDidCancelOperation(_ omnibar: Omnibar) {
        adaptee.insertCompletion(
            word,
            forPartialWordRange: partialWordRange,
            movement: .cancel,
            isFinal: true
        )
    }

    func omnibar(_ omnibar: Omnibar, didChangeContent contentChange: OmnibarContentChange, method: ChangeMethod) {
        // TODO: get this to fire when selection changes
    }

    func omnibar(_ omnibar: Omnibar, commit text: String) {
        textKitAutoCompletion.insertCompletion(
            text,
            forPartialWordRange: partialWordRange,
            movement: .return,
            isFinal: true
        )
    }
}

extension OmnibarTextKitAutoCompletionAdapter where Adaptee: NSTextView {
    convenience init(textView: NSTextView) {
        guard let textStorage = textView.textStorage else { preconditionFailure("NSTextView should have a text storage") }
        self.init(
            adaptee: textView,
            word: textStorage.mutableString.substring(with: textView.rangeForUserCompletion),
            partialWordRange: textView.rangeForUserCompletion
        )
    }
}
