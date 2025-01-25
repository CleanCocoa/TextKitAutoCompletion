//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextKitAutoCompletion

/// Offers live completion while typing.
///
/// - Hashtag completion is triggered by typing a `#`,
/// - Dictionary word completion is triggered via `F5` or `⌥+ESC` (system default completion shortcuts).
@MainActor
class TypeToCompleteTextView: RangeConfigurableTextView {
    // ⚠️ Take good care of releasing this strong reference in response to lifecycle callbacks from the controller to break up the retain cycle.
    var completionPopoverController: CompletionPopoverController? {
        didSet {
            if completionPopoverController !== oldValue {
                oldValue?.close()
            }
        }
    }

    var isCompleting: Bool { completionPopoverController?.isCompleting ?? false }

    override func insertText(_ string: Any, replacementRange: NSRange) {
        super.insertText(string, replacementRange: replacementRange)

        // TODO: Consider to cancel completion when the range shifts while typing. E.g. typing a word, "hello", that narrows down results; then type a non-letter-character like "%" or "(", it resets the rangeForUserCompletion to (the empty) range after that symbol, suggesting from the whole dictionary again. Similar to cancel when hitting space, typing any non-word character should cancel. This maybe better controlled from here instead of the popover.
        continueCompletionIfAny()

        if !isCompleting {
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
        continueCompletionIfAny()
    }

    override func complete(_ sender: Any?) {
        let partialWordRange = self.rangeForUserCompletion

        /// Unused by our approach, but required by the API; selection is reflected in the completion window directly.
        var indexOfSelectedItem: Int = -1
        let completions = self.completions(
            forPartialWordRange: partialWordRange,
            indexOfSelectedItem: &indexOfSelectedItem
        )?.map(CompletionCandidate.init(_:))

        guard let completions,
              !completions.isEmpty
        else {
            if isCompleting {
                cancelCompleting()
            } else {
                NSSound.beep()
            }
            return
        }

        startCompleting(completionCandidates: completions, forPartialWordRange: partialWordRange)
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

    // MARK: - Completion lifecycle

    private func startCompleting(
        completionCandidates: [CompletionCandidate],
        forPartialWordRange partialWordRange: NSRange
    ) {
        guard let textStorage else { preconditionFailure("NSTextView should have a text storage") }

        self.completionPopoverController = self.completionPopoverController
            ?? CompletionPopoverController(textView: self)

        assert(self.completionPopoverController != nil)
        self.completionPopoverController?.display(
            completionCandidates: completionCandidates,
            forPartialWordRange: partialWordRange,
            originalString: textStorage.mutableString.substring(with: partialWordRange)
        )
    }


    /// Forward typing in text view *during* completion to the completion UI, live-updating suggestions.
    private func continueCompletionIfAny() {
        if isCompleting {
            complete(self)
        }
    }

    private func cancelCompleting() {
        assert(isCompleting, "Calling \(#function) is expected only during active completion")
        completionPopoverController?.close()
        completionPopoverController = nil
    }
}
