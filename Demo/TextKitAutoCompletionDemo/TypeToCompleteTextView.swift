//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextKitAutoCompletion

extension NSRange {
    @inlinable @inline(__always)
    func intersects(with other: NSRange) -> Bool {
        self.intersection(other) != nil
    }
}

@MainActor
protocol CompletionLifecycleDelegate: AnyObject {
    var isCompleting: Bool { get }

    func startCompleting(
        textView: NSTextView,
        completionCandidates: [CompletionCandidate],
        forPartialWordRange partialWordRange: NSRange,
        originalString: String
    )

    /// Do not start, but continue a completing session.
    ///
    /// Use to forward typing events in the text view *during* completion to the completion UI to get live-updating suggestions.
    func continueCompleting(textView: NSTextView)

    func stopCompleting(textView: NSTextView)
}

@MainActor
class TypeToCompleteTextView: RangeConfigurableTextView {
    enum CompletionMode {
        /// Completion is triggered via `F5` or `⌥+ESC` (system default completion shortcuts).
        case manual

        /// Hashtag completion, triggered by typing a `#`.
        case hashtagAutocompletion
    }

    weak var completionLifecycleDelegate: CompletionLifecycleDelegate?

    var completionMode: CompletionMode? = nil
    var isCompleting: Bool { completionMode != nil }

    private func trackingRangeForUserCompletionChange(during block: () -> Void) -> Bool {
        let rangeForCompletionBeforeTyping = self.rangeForUserCompletion

        block()

        let rangeForCompletionAfterTyping = self.rangeForUserCompletion
        return !rangeForCompletionBeforeTyping.intersects(with: rangeForCompletionAfterTyping)
    }

    override func insertText(_ string: Any, replacementRange: NSRange) {
        // `insertText(_:replacementRange:)` accepts both NSString and NSAttributedString, so we need to unwrap this.
        guard let insertString = (string as? String) ?? (string as? NSAttributedString)?.string
        else { preconditionFailure("\(#function) called with non-string value") }

        /// Indicates that the previous completion context has been lost, e.g. when typing whitespace or punctuation marks to separate words.
        let typingDidResetRange = trackingRangeForUserCompletionChange {
            super.insertText(string, replacementRange: replacementRange)
        }

        let cancelCompletion = isCompleting && typingDidResetRange
        if cancelCompletion {
            completionLifecycleDelegate?.stopCompleting(textView: self)
        }
        else {
            completionLifecycleDelegate?.continueCompleting(textView: self)

            triggerAutocompletion(fromTyping: insertString)
        }
    }

    private func triggerAutocompletion(fromTyping insertString: String) {
        // Auto-completion is not supposed to replace in-progress completions.
        guard !isCompleting else { return }

        if insertString == "#" {
            self.completionMode = self.completionMode ?? .hashtagAutocompletion
            complete(self)
        }
    }

    override func deleteBackward(_ sender: Any?) {
        super.deleteBackward(sender)
        completionLifecycleDelegate?.continueCompleting(textView: self)
    }

    override func complete(_ sender: Any?) {
        guard let textStorage else { preconditionFailure("NSTextView should have a text storage") }

        let isContinuingCompletion = self.isCompleting
        let partialWordRange = self.rangeForUserCompletion

        /// Unused by our approach, but required by the API; selection is reflected in the completion window directly.
        // TODO: We could use indexOfSelectedItem for restoration of selected items when typing.
        var indexOfSelectedItem: Int = -1
        let completions = self.completions(
            forPartialWordRange: partialWordRange,
            indexOfSelectedItem: &indexOfSelectedItem
        )?.map(CompletionCandidate.init(_:))

        guard let completions,
              !completions.isEmpty
        else {
            if isContinuingCompletion {
                completionLifecycleDelegate?.stopCompleting(textView: self)
                completionMode = nil
            } else if case .manual = completionMode {
                // For manual ('forced') invocation, produce error sound. Avoid beeping for the auto-completion while typing hashtags.
                NSSound.beep()
            }
            return
        }

        self.completionMode = self.completionMode ?? .manual

        completionLifecycleDelegate?.startCompleting(
            textView: self,
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
            completionLifecycleDelegate?.stopCompleting(textView: self)
            completionMode = nil
        }
    }
}
