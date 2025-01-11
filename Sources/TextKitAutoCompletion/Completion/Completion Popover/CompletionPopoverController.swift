//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

@MainActor
public class CompletionPopoverController: NSObject, NSPopoverDelegate {
    let textView: NSTextView

    lazy var controller = CompletionViewController(textView: textView)

    lazy var popover: NSPopover = {
        let popover = NSPopover()
        popover.delegate = self
        popover.behavior = .transient
        popover.contentViewController = controller
        return popover
    }()

    /// Caches the previous key window and its responder to restore focus when the popover shows.
    private var firstResponderBeforePopover: (window: NSWindow, firstResponder: NSResponder)?

    /// Reports whether the popover controller is currently in an active completion session.
    public private(set) var isCompleting = false

    public init(textView: NSTextView) {
        self.textView = textView
    }

    public func display(
        completionCandidates: [CompletionCandidate],
        forPartialWordRange partialWordRange: NSRange,
        originalString: String
    ) {
        guard let window = textView.window else { preconditionFailure("Views on screen are expected to have windows") }
        defer { isCompleting = true }

        // Don't move the popover with the insertion point to reduce motion and offer visual anchor for the user to look at while they type to complete.
        if !popover.isShown {
            let selectionRectInScreenCoordinates = textView.firstRect(forCharacterRange: textView.selectedRange(), actualRange: nil)
            let selectionRectInWindow = window.convertFromScreen(selectionRectInScreenCoordinates)
            let selectionRectInTextView = textView.convert(selectionRectInWindow, from: nil)

            var popoverReferenceRect = selectionRectInTextView
            // Insertion point is a zero-width rect, but these will be discarded and the popover will resort to showing on the view's edge. A height of _0_ I haven't encountered, yet, but for consistency make the same guarantee.
            popoverReferenceRect.size.width = max(popoverReferenceRect.size.width, 1)
            popoverReferenceRect.size.height = max(popoverReferenceRect.size.height, 1)

            popover.show(relativeTo: popoverReferenceRect, of: textView, preferredEdge: .maxY)
        }

        controller.show(
            completionCandidates: completionCandidates,
            forPartialWordRange: partialWordRange,
            originalString: originalString
        )
    }

    public func close() {
        isCompleting = false
        // Close popover after changing `isCompleting` so that `popoverWillClose(_:)` won't fire a cancelation.
        popover.close()
    }

    public func popoverWillClose(_ notification: Notification) {
        guard isCompleting else { return }
        controller.cancelOperation(self)
    }
}
