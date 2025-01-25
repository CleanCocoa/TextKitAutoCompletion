//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextKitAutoCompletion

@main @MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var window: NSWindow!
    @IBOutlet var textField: NSTextField!
    lazy var completionLifecycleController = CompletionLifecycleController()
    @IBOutlet var textView: TypeToCompleteTextView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        textView.completionLifecycleDelegate = completionLifecycleController
        textView.strategy = HashtagRangeStrategy(wrapping: WordRangeStrategy())
    }

    @IBAction func focusTextField(_ sender: Any) {
        // Used as the action of another responder in the window to interactively test whether auto-completion popover dismissal behaves correctly.
        window.makeFirstResponder(textField)
    }
}
