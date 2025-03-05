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
        textView.strategy = HashtagRangeStrategy(wrapping: WordRangeStrategy(), isMatchingFirstHash: true)
    }

    @IBAction func focusTextField(_ sender: Any) {
        // Used as the action of another responder in the window to interactively test whether auto-completion popover dismissal behaves correctly.
        window.makeFirstResponder(textField)
    }
}

// MARK: - Shortcut resolution

// With this setup, the text view interprets Cmd+Backspace as `NSStandardKeyBindingResponding.deleteToBeginningOfLine(_:)`.  With an active completion popover, though, the text view by default isn't performing key equivalents anymore, and main menu shortcut resolution wins. This can be a surprise for users to whom the completion UI is part of the text editing experience. In order to verify that we don't violate their mental model, this setup demonstrates how the main menu item's target/action mechanism is not invoked from the text view with and without active completion.

extension AppDelegate {
    /// Action for main menu items to verify that text editing shortcuts 'win' when the completion popover is visible. (E.g. Cmd+Backspace to delete to beginning of line.)
    @IBAction func conflictingDemoShortcut(_ sender: NSMenuItem) {
        let alert = NSAlert()
        alert.messageText = "Main Menu Shortcut Invoked"
        alert.informativeText = sender.title
        alert.runModal()
    }
}

extension TypeToCompleteTextView {
    private enum DeleteKey: UInt16 {
        /// Corresponds to Carbon's `kVK_Delete`
        case delete = 51

        /// Corresponds to Carbon's `kVK_ForwardDelete`
        case forwardDelete = 117
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let shouldRespondToEvent = (self.window?.firstResponder == self)
            || (isCompleting && completionLifecycleDelegate?.isCompleting == true)

        // Re-implement Cmd-Backspace shortcut to delete a line to override NSMenuItem shortcut to delete a file
        if shouldRespondToEvent,
           event.modifierFlags.contains(.command),
           let key = DeleteKey(rawValue: event.keyCode),
           key == .delete || key == .forwardDelete {

            self.interpretKeyEvents([event])
            return true
        }

        return super.performKeyEquivalent(with: event)
    }
}
