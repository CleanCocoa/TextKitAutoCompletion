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

    var completionController: CompletionController?

    override func complete(_ sender: Any?) {
        guard let window = self.window else { preconditionFailure("Views are expected to have windows") }
        completionController = CompletionController()
        let partialWordRange = self.rangeForUserCompletion
        var indexOfSelectedItem: Int = -1
        let selectionRectInScreenCoordinates = self.firstRect(forCharacterRange: self.selectedRange(), actualRange: nil)
        let selectionRectInWindow = window.convertFromScreen(selectionRectInScreenCoordinates)
        let selectionRect = self.convert(selectionRectInWindow, from: nil)
        completionController!.display(
            completions: completions(
                forPartialWordRange: partialWordRange,
                indexOfSelectedItem: &indexOfSelectedItem
            ) ?? ["test"],
            indexOfSelectedItem: indexOfSelectedItem,
            forPartialWordRange: partialWordRange,
            originalString: self.attributedString().attributedSubstring(from: partialWordRange).string,
            relativeTo: selectionRect,
            forTextView: self
        )
    }
}

class CompletionController {
    lazy var controller = CompletionPopoverController()

    lazy var popover: NSPopover = {
        let popover = NSPopover()
        popover.contentViewController = controller
        return popover
    }()

    deinit {
        popover.close()
    }

    func display(
        completions: [String],
        indexOfSelectedItem: Int,
        forPartialWordRange partialWordRange: NSRange,
        originalString: String,
        relativeTo rect: NSRect,
        forTextView textView: NSTextView
    ) {
        var rect = rect
        rect.size.width = max(rect.size.width, 1)  // Zero-width rect will be discarded and the popover will resort to showing on the view's edge.
        popover.show(relativeTo: rect, of: textView, preferredEdge: .minY)
        controller.showCompletions(completions)
    }
}
