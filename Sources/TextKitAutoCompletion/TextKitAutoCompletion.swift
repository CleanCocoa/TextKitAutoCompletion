//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

/// Formal protocol definition for `NSTextView`'s completion API, extracted from `NSTextView` including documentation.
@MainActor
public protocol TextKitAutoCompletion {
    /// The partial range from the most recent beginning of a word up to the insertion point.
    ///
    /// This value is intended to be used for the range argument in the text completion methods such as completions(forPartialWordRange:indexOfSelectedItem:).
    var rangeForUserCompletion: NSRange { get }

    /// Returns an array of potential completions, in the order to be presented, representing possible word completions available from a partial word.
    ///
    /// May be overridden by subclasses to modify or override the list of possible completions.
    ///
    /// This method should call the `NSTextViewDelegate` method `textView(_:completions:forPartialWordRange:indexOfSelectedItem:)` if the delegate implements such a method.
    ///
    /// - Parameters:
    ///   - charRange: The range of characters of the matched partial word to be completed.
    ///   - index: On return, optionally set to the completion that should be initially selected. The default is 0, and –1 indicates no selection.
    /// - Returns: An array of potential completions, in the order to be presented, representing possible word completions available from a partial word at `charRange`. Returning `nil` or a zero-length array suppresses completion.
    func completions(
        forPartialWordRange charRange: NSRange,
        indexOfSelectedItem index: UnsafeMutablePointer<Int>
    ) -> [String]?

    /// Inserts the selected completion into the text at the appropriate location.
    ///
    /// This method has two effects, text substitution and changing of the selection:
    ///
    /// - It replaces the text between `charRange.start` and the current insertion point with `word`.
    /// - If `isFinishingCompletion` is `false` it changes the selection to be the last _n_ characters of word where _n_ is equal to `word.length` minus `charRange.length`, that is, the potential completion.
    /// - If `isFinishingCompletion` is `true` it makes the selection empty and puts the insertion point just after word.
    ///
    /// - Parameters:
    ///   - word: The text to insert, including the matched partial word and its potential completion.
    ///   - charRange:  The range of characters of the matched partial word to be completed.
    ///   - movement: The direction of movement. For possible values see the `NSText` Constants section. This value allows subclasses to distinguish between canceling completion and selection by arrow keys, by return, by tab, or by other means such as clicking.
    ///   - isFinishingCompletion: false while the user navigates through the potential text completions, true when a completion is definitively selected or cancelled and the original value is reinserted.
    func insertCompletion(
        _ word: String,
        forPartialWordRange charRange: NSRange,
        movement: Int,
        isFinal isFinishingCompletion: Bool
    )

    /// Invokes completion in a text view.
    ///
    /// By default invoked using the F5 key, this method provides users with a choice of completions for the word currently being typed. May be invoked programmatically if autocompletion is desired by a client of the text system. You can change the key invoking this method using the text system’s key bindings mechanism; see "Text System Defaults and Key Bindings" for an explanation of the procedure.
    ///
    /// The delegate may replace or modify the list of possible completions by implementing `textView(_:completions:forPartialWordRange:indexOfSelectedItem:)`. Subclasses can control the list by overriding `completions(forPartialWordRange:indexOfSelectedItem:)`.
    /// - Parameter sender: The control sending the message. May be `nil`.
    func complete(_ sender: Any?)
}

extension TextKitAutoCompletion {
    /// Inserts the selected completion into the text at the appropriate location.
    ///
    /// This method has two effects, text substitution and changing of the selection:
    ///
    /// - It replaces the text between `charRange.start` and the current insertion point with `word`.
    /// - If `isFinishingCompletion` is `false` it changes the selection to be the last _n_ characters of word where _n_ is equal to `word.length` minus `charRange.length`, that is, the potential completion.
    /// - If `isFinishingCompletion` is `true` it makes the selection empty and puts the insertion point just after word.
    ///
    /// - Parameters:
    ///   - word: The text to insert, including the matched partial word and its potential completion.
    ///   - charRange:  The range of characters of the matched partial word to be completed.
    ///   - movement: The direction of movement. For possible values see the `NSText` Constants section. This value allows subclasses to distinguish between canceling completion and selection by arrow keys, by return, by tab, or by other means such as clicking.
    ///   - isFinishingCompletion: false while the user navigates through the potential text completions, true when a completion is definitively selected or cancelled and the original value is reinserted.
    @inlinable @inline(__always)
    public func insertCompletion(
        _ word: String,
        forPartialWordRange charRange: NSRange,
        movement: NSTextMovement,
        isFinal isFinishingCompletion: Bool
    ) {
        self.insertCompletion(word, forPartialWordRange: charRange, movement: movement.rawValue, isFinal: isFinishingCompletion)
    }
}
