//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

@MainActor
public class CompletionPopoverController: NSObject, NSPopoverDelegate {
    lazy var controller = CompletionViewController()

    lazy var popover: NSPopover = {
        let popover = NSPopover()
        popover.delegate = self
        popover.behavior = .transient
        popover.contentViewController = controller
        return popover
    }()

    /// Reports whether the popover controller is currently in an active completion session.
    public private(set) var isCompleting = false

    public func display(
        completionCandidates: [CompletionCandidate],
        forPartialWordRange partialWordRange: NSRange,
        originalString: String,
        relativeToInsertionPointOfTextView textView: NSTextView
    ) {
        guard let window = textView.window else { preconditionFailure("Views on screen are expected to have windows") }

        let selectionRectInScreenCoordinates = textView.firstRect(forCharacterRange: textView.selectedRange(), actualRange: nil)
        let selectionRectInWindow = window.convertFromScreen(selectionRectInScreenCoordinates)
        let selectionRectInTextView = textView.convert(selectionRectInWindow, from: nil)

        display(
            completionCandidates: completionCandidates,
            forPartialWordRange: partialWordRange,
            originalString: originalString,
            relativeTo: selectionRectInTextView,
            forTextView: textView
        )
    }

    /// Display completion candidates in a text view.
    ///
    /// This mimicks, but doesn't match, the private `NSTextViewCompletionController` call, which would be:
    ///
    ///   -[NSTextViewCompletionController displayCompletions:indexOfSelectedItem:forPartialWordRange:originalString:atPoint:forTextView:]
    public func display(
        completionCandidates: [CompletionCandidate],
        forPartialWordRange partialWordRange: NSRange,
        originalString: String,
        relativeTo rect: NSRect,
        forTextView textView: NSTextView
    ) {
        defer { isCompleting = true }
        var rect = rect
        // Insertion point is a zero-width rect, but these will be discarded and the popover will resort to showing on the view's edge. A height of _0_ I haven't encountered, yet, but for consistency make the same guarantee.
        rect.size.width = max(rect.size.width, 1)
        rect.size.height = max(rect.size.height, 1)
        popover.show(relativeTo: rect, of: textView, preferredEdge: .minY)
        controller.showCompletionCandidates(completionCandidates, in: textView)
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
