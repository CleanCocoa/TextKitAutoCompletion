//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextKitAutoCompletion

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var window: NSWindow!
    @IBOutlet var textField: NSTextField!
    @IBOutlet var textView: TypeToCompleteTextView!

    @IBAction func focusTextField(_ sender: Any) {
        // Used as the action of another responder in the window to interactively test whether auto-completion popover dismissal behaves correctly.
        window.makeFirstResponder(textField)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        textView.strategy = HashtagRangeStrategy(wrapping: WordRangeStrategy())
    }
}
