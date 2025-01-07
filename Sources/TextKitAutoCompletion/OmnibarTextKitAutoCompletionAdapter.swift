//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import Omnibar

class OmnibarTextKitAutoCompletionAdapter<Adaptee>: OmnibarContentChangeDelegate
where Adaptee: TextKitAutoCompletion {
    let adaptee: Adaptee
    var word: String
    var partialWordRange: NSRange

    init(
        adaptee: Adaptee,
        word: String,
        partialWordRange: NSRange
    ) {
        self.adaptee = adaptee
        self.word = word
        self.partialWordRange = partialWordRange
    }

    func omnibarDidCancelOperation(_ omnibar: Omnibar) {
        cancel()
    }

    func cancel() {
        adaptee.insertCompletion(
            word,
            forPartialWordRange: partialWordRange,
            movement: .cancel,
            isFinal: true
        )
    }

    func omnibar(_ omnibar: Omnibar, didChangeContent contentChange: OmnibarContentChange, method: ChangeMethod) {
        adaptee.insertCompletion(
            contentChange.string,
            forPartialWordRange: partialWordRange,
            movement: .other,
            isFinal: false
        )
    }

    func omnibar(_ omnibar: Omnibar, commit text: String) {
        adaptee.insertCompletion(
            text,
            forPartialWordRange: partialWordRange,
            movement: .return,
            isFinal: true
        )
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
