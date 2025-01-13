//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var window: NSWindow!
    @IBOutlet var textField: NSTextField!
    @IBOutlet var textView: NSTextView!

    @IBAction func focusTextField(_ sender: Any) {
        // Used as the action of another responder in the window to interactively test whether auto-completion popover dismissal behaves correctly.
        window.makeFirstResponder(textField)
    }
}
