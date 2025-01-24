//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextKitAutoCompletion

/// Offers live completion while typing, triggered by a `#`, in addition to manually invoking the completion UI via `F5` or `⌥+ESC`.
@MainActor
class TypeToCompleteTextView: RangeConfigurableTextView {
    override func insertText(_ string: Any, replacementRange: NSRange) {
        super.insertText(string, replacementRange: replacementRange)

        if isCompleting {
            // Forward typing in text view *during* completion to the completion UI, live-updating suggestions.
            complete(self)
        } else {
            // `insertText(_:replacementRange:)` accepts both NSString and NSAttributedString, so we need to unwrap this.
            let string = (string as? String)
                ?? (string as? NSAttributedString)?.string

            if string == "#" {
                complete(self)
            }
        }
    }

    override func deleteBackward(_ sender: Any?) {
        super.deleteBackward(sender)

        if isCompleting {
            // Forward typing in text view *during* completion to the completion UI, live-updating suggestions.
            complete(self)
        }
    }

    // ⚠️ Take good care of releasing this strong reference in response to lifecycle callbacks from the controller to break up the retain cycle.
    var completionPopoverController: CompletionPopoverController? {
        didSet {
            oldValue?.close()
        }
    }

    var isCompleting: Bool { completionPopoverController?.isCompleting ?? false }

    override func complete(_ sender: Any?) {
        let partialWordRange = self.rangeForUserCompletion
        /// Unused by our approach; selection is reflected in the completion window directly.
        var indexOfSelectedItem: Int = -1

        let completions = self.completions(
            forPartialWordRange: partialWordRange,
            indexOfSelectedItem: &indexOfSelectedItem
        )?.map(CompletionCandidate.init(_:))
        guard let completions, !completions.isEmpty else {
            if isCompleting {
                completionPopoverController?.close()
            } else {
                NSSound.beep()
            }
            return
        }

        let completionPopoverController = {
            if let existingController = self.completionPopoverController {
                return existingController
            } else {
                let newController = CompletionPopoverController(textView: self)
                self.completionPopoverController = newController
                return newController
            }
        }()

        guard let textStorage else { preconditionFailure("NSTextView should have a text storage") }

        completionPopoverController.display(
            completionCandidates: completions,
            forPartialWordRange: partialWordRange,
            originalString: textStorage.mutableString.substring(with: partialWordRange)
        )
    }

    override func insertCompletion(_ word: String, forPartialWordRange charRange: NSRange, movement: Int, isFinal isFinishingCompletion: Bool) {
        // Closing the popover cancels completion via `insertCompletion(_, charRange: _, movement: .cancel, isFinal: true)`, but we also close the popover upon completion. To avoid accepting a completion, followed by an automatic cancel message, we need to (a) check whether we're still actively completing anything (this approach), or (b) implement reacting to the `NSPopover` closing differently.
        guard isCompleting else { return }

        super.insertCompletion(word, forPartialWordRange: charRange, movement: movement, isFinal: isFinishingCompletion)

        if isFinishingCompletion {
            completionPopoverController?.close()
            completionPopoverController = nil
        }
    }
}
