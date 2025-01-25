//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextKitAutoCompletion

extension NSRange {
    @inlinable @inline(__always)
    func intersects(with other: NSRange) -> Bool {
        self.intersection(other) != nil
    }
}

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

        let rangeForCompletionBeforeTyping = self.rangeForUserCompletion
        super.insertText(string, replacementRange: replacementRange)
        let rangeForCompletionAfterTyping = self.rangeForUserCompletion
        /// Indicates that the previous completion context has been lost, e.g. when typing whitespace or punctuation marks to separate words.
        let typingDidResetRange = !rangeForCompletionBeforeTyping.intersects(with: rangeForCompletionAfterTyping)

        let cancelCompletion = isCompleting && typingDidResetRange
        if !cancelCompletion { continueCompleting() }
        defer { if cancelCompletion { stopCompleting() } }

        if !isCompleting {
            // `insertText(_:replacementRange:)` accepts both NSString and NSAttributedString, so we need to unwrap this.
            guard let insertString = (string as? String) ?? (string as? NSAttributedString)?.string
            else { preconditionFailure("\(#function) called with non-string value") }

            if insertString == "#" {
                complete(self)
            }
        }
    }

    override func deleteBackward(_ sender: Any?) {
        super.deleteBackward(sender)
        continueCompleting()
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
                stopCompleting()
            } else {
                // TODO: Only beep for manual invocations. Esp. avoid beeping when typing "#####", which triggers completion, but has no candidates.
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
            stopCompleting()
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

    /// Do not start, but continue a completing session.
    ///
    /// Use to forward typing events in the text view *during* completion to the completion UI to get live-updating suggestions.
    private func continueCompleting() {
        guard isCompleting else { return }
        complete(self)
    }

    private func stopCompleting() {
        assert(isCompleting, "Calling \(#function) is expected only during active completion")
        completionPopoverController?.close()
        completionPopoverController = nil
    }
}
