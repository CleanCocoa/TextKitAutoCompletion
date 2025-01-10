//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextKitAutoCompletion

/// Offers live completion while typing, triggered by a `#`, in addition to manually invoking the completion UI via `F5` or `⌥+ESC`.
@MainActor
class TypeToCompleteTextView: NSTextView {
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

    var completionPopoverController: CompletionPopoverController? {
        didSet {
            oldValue?.close()
        }
    }

    var isCompleting: Bool { completionPopoverController?.isCompleting ?? false }

    override var rangeForUserCompletion: NSRange {
        var range = super.rangeForUserCompletion
        guard range.length > 0,
              let substring = textStorage?.mutableString.substring(with: range) as NSString?,
              case let hashPrefixRange = substring.range(of: "#", options: .anchored),
              hashPrefixRange.location >= 0, hashPrefixRange.length > 0
        else { return range }
        range.location += hashPrefixRange.length
        range.length -= hashPrefixRange.length
        return range
    }

    override func complete(_ sender: Any?) {
        let partialWordRange = self.rangeForUserCompletion
        /// Unused by our approach; selection is reflected in the completion window directly.
        var indexOfSelectedItem: Int = -1

        let completions = self.completions(
            forPartialWordRange: partialWordRange,
            indexOfSelectedItem: &indexOfSelectedItem
        )?.map(CompletionCandidate.init(_:))
        guard let completions else { NSSound.beep(); return }

        let completionPopoverController = {
            if let existingController = self.completionPopoverController {
                return existingController
            } else {
                let newController = CompletionPopoverController()
                self.completionPopoverController = newController
                return newController
            }
        }()

        completionPopoverController.display(
            completionCandidates: completions,
            forPartialWordRange: partialWordRange,
            originalString: self.attributedString().attributedSubstring(from: partialWordRange).string,  // FIXME: use text storage
            relativeToInsertionPointOfTextView: self
        )
    }

    override func insertCompletion(_ word: String, forPartialWordRange charRange: NSRange, movement: Int, isFinal flag: Bool) {
        // Closing the popover cancels completion via `insertCompletion(_, charRange: _, movement: .cancel, isFinal: true)`, but we also close the popover upon completion. To avoid accepting a completion, followed by an automatic cancel message, we need to (a) check whether we're still actively completing anything (this approach), or (b) implement reacting to the `NSPopover` closing differently.
        guard isCompleting else { return }

        super.insertCompletion(word, forPartialWordRange: charRange, movement: movement, isFinal: flag)

        if flag {
            completionPopoverController?.close()
            completionPopoverController = nil
        }
    }
}
