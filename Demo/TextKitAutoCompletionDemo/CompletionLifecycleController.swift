//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextKitAutoCompletion

@MainActor
final class CompletionLifecycleController: CompletionLifecycleDelegate {
    private var completionPopoverController: CompletionPopoverController? {
        didSet {
            if completionPopoverController !== oldValue {
                oldValue?.close()
            }
        }
    }

    var isCompleting: Bool { completionPopoverController?.isCompleting ?? false }

    func startCompleting(
        textView: NSTextView,
        completionCandidates: [CompletionCandidate],
        forPartialWordRange partialWordRange: NSRange,
        originalString: String
    ) {
        self.completionPopoverController = self.completionPopoverController
            ?? CompletionPopoverController(textView: textView)

        assert(self.completionPopoverController != nil)
        self.completionPopoverController?.display(
            completionCandidates: completionCandidates,
            forPartialWordRange: partialWordRange,
            originalString: originalString
        )
    }

    /// Do not start, but continue a completing session.
    ///
    /// Use to forward typing events in the text view *during* completion to the completion UI to get live-updating suggestions.
    func continueCompleting(textView: NSTextView) {
        guard isCompleting else { return }
        textView.complete(self)
    }

    func stopCompleting(textView: NSTextView) {
        assert(isCompleting, "Calling \(#function) is expected only during active completion")
        completionPopoverController?.close()
        completionPopoverController = nil
    }
}
