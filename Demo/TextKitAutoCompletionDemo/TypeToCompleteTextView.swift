//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextKitAutoCompletion

/// Offers live completion while typing, triggered by a `#`, in addition to manually invoking the completion UI via `F5` or `⌥+ESC`.
class TypeToCompleteTextView: NSTextView {
    override func insertText(_ string: Any, replacementRange: NSRange) {
        super.insertText(string, replacementRange: replacementRange)

        // `insertText(_:replacementRange:)` accepts both NSString and NSAttributedString, so we need to unwrap this.
        let string = (string as? String)
            ?? (string as? NSAttributedString)?.string

        if string == "#" {
            complete(self)
        }
    }

    var completionController: CompletionController? {
        didSet {
            oldValue?.close()
        }
    }

    var isCompleting: Bool { completionController?.isCompleting ?? false }

    override func complete(_ sender: Any?) {
        guard let window = self.window else { preconditionFailure("Views are expected to have windows") }

        let partialWordRange = self.rangeForUserCompletion
        /// Unused by our approach; selection is reflected in the completion window directly.
        var indexOfSelectedItem: Int = -1

        let completions = self.completions(
            forPartialWordRange: partialWordRange,
            indexOfSelectedItem: &indexOfSelectedItem
        )?.map(CompletionCandidate.init(_:))
        guard let completions else { NSSound.beep(); return }

        let completionController = CompletionController()
        defer { self.completionController = completionController }

        let selectionRectInScreenCoordinates = self.firstRect(forCharacterRange: self.selectedRange(), actualRange: nil)
        let selectionRectInWindow = window.convertFromScreen(selectionRectInScreenCoordinates)
        let selectionRect = self.convert(selectionRectInWindow, from: nil)
        completionController.display(
            completions: completions,
            forPartialWordRange: partialWordRange,
            originalString: self.attributedString().attributedSubstring(from: partialWordRange).string,
            relativeTo: selectionRect,
            forTextView: self
        )
    }

    override func insertCompletion(_ word: String, forPartialWordRange charRange: NSRange, movement: Int, isFinal flag: Bool) {
        // Closing the popover cancels completion via `insertCompletion(_, charRange: _, movement: .cancel, isFinal: true)`, but we also close the popover upon completion. To avoid accepting a completion, followed by an automatic cancel message, we need to (a) check whether we're still actively completing anything (this approach), or (b) implement reacting to the `NSPopover` closing differently.
        guard isCompleting else { return }

        super.insertCompletion(word, forPartialWordRange: charRange, movement: movement, isFinal: flag)

        if flag {
            completionController?.close()
            completionController = nil
        }
    }
}

class CompletionController: NSObject, NSPopoverDelegate {
    lazy var controller = CompletionPopoverController()

    lazy var popover: NSPopover = {
        let popover = NSPopover()
        popover.delegate = self
        popover.behavior = .transient
        popover.contentViewController = controller
        return popover
    }()

    private(set) var isCompleting = false

    func display(
        completions: [CompletionCandidate],
        forPartialWordRange partialWordRange: NSRange,
        originalString: String,
        relativeTo rect: NSRect,
        forTextView textView: NSTextView
    ) {
        defer { isCompleting = true }
        var rect = rect
        rect.size.width = max(rect.size.width, 1)  // Zero-width rect will be discarded and the popover will resort to showing on the view's edge.
        popover.show(relativeTo: rect, of: textView, preferredEdge: .minY)
        controller.showCompletionCandidates(completionCandidates, in: textView)
    }

    func close() {
        isCompleting = false
        // Close popover after changing `isCompleting` so that `popoverWillClose(_:)` won't fire a cancelation.
        popover.close()
    }

    func popoverWillClose(_ notification: Notification) {
        guard isCompleting else { return }
        controller.cancelOperation(self)
    }
}
