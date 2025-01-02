//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

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
}
