//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

@MainActor
class CompletionAdapter<Adaptee>
where Adaptee: TextKitAutoCompletion {
    let adaptee: Adaptee
    fileprivate var originalString: String
    fileprivate var partialWordRange: NSRange

    init(
        adaptee: Adaptee,
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

extension CompletionAdapter: DisplaysBestFit {
    func display(bestFit: CompletionCandidate, forSearchTerm searchTerm: String) {
        suggestCompletion(text: bestFit.value)
    }
}

extension CompletionAdapter where Adaptee: NSTextView {
    convenience init(textView adaptee: Adaptee) {
        guard let textStorage = adaptee.textStorage else { preconditionFailure("NSTextView should have a text storage") }
        self.init(
            adaptee: adaptee,
            originalString: textStorage.mutableString.substring(with: adaptee.rangeForUserCompletion),
            partialWordRange: adaptee.rangeForUserCompletion
        )
    }
}
