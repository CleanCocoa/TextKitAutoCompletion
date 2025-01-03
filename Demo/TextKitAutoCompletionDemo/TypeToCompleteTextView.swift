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
        completionController = CompletionController()
        let partialWordRange = self.rangeForUserCompletion
        var indexOfSelectedItem: Int = -1
        completionController!.display(
            completions: completions(
                forPartialWordRange: partialWordRange,
                indexOfSelectedItem: &indexOfSelectedItem
            ) ?? ["test"],
            indexOfSelectedItem: indexOfSelectedItem,
            forPartialWordRange: partialWordRange,
            originalString: self.attributedString().attributedSubstring(from: partialWordRange).string,
            atPoint: self.layoutManager!.location(forGlyphAt: self.layoutManager!.glyphIndexForCharacter(at: self.selectedRange().location)),
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
        atPoint point: NSPoint,
        forTextView textView: NSTextView
    ) {
        popover.show(relativeTo: NSRect(origin: point, size: .zero), of: textView, preferredEdge: .minY)
        controller.showCompletions(completions)
    }
}
