//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextKitAutoCompletion

extension NSRange {
    @inlinable @inline(__always)
    func intersects(with other: NSRange) -> Bool {
        self.intersection(other) != nil
    }
}

@MainActor
protocol CompletionLifecycleDelegate: AnyObject {
    var isCompleting: Bool { get }
    var completionPartialWordRange: NSRange? { get }

    func startCompleting(
        textView: NSTextView,
        completionCandidates: [CompletionCandidate],
        forPartialWordRange partialWordRange: NSRange,
        originalString: String
    )

    /// Do not start, but continue a completing session.
    ///
    /// Use to forward typing events in the text view *during* completion to the completion UI to get live-updating suggestions.
    func continueCompleting(textView: NSTextView)

    func stopCompleting(textView: NSTextView)
}

@MainActor
class TypeToCompleteTextView: NSTextView /* Not using RangeConfigurableTextView because we want multiple strategies. */ {
    enum CompletionMode {
        /// Completion is triggered via `F5` or `⌥+ESC` (system default completion shortcuts).
        case manual

        /// Hashtag completion, triggered by typing a `#`; also manually invoked via `F5` or `⌥+ESC` (system default completion shortcuts) next to as hash.
        case hashtag

        /// Wiki link completion, triggered by typing `[[`.
        case wikilink
    }

    weak var completionLifecycleDelegate: CompletionLifecycleDelegate?

    private lazy var wordRangeStrategy = WordRangeStrategy()
    private lazy var hashtagRangeStrategy = HashtagRangeStrategy(
        wrapping: wordRangeStrategy,
        isMatchingFirstHash: true // include "#" in range, used to disambiguate "##inbox" from "#inbox"
    )
    private lazy var wikilinkRangeStrategy = WikilinkRangeStrategy(wrapping: wordRangeStrategy)

    override var rangeForUserCompletion: NSRange {
        // Since we support multiple completion modes and don't rely on `RangeConfigurableTextView.rangeForUserCompletion` dynamically dispatching to the appropriate strategy, we can change the completion range based on the current completion mode.
        switch completionMode {
        case .hashtag: hashtagRangeStrategy.rangeForUserCompletion(textView: self)
        case .wikilink: wikilinkRangeStrategy.rangeForUserCompletion(textView: self)
        case .manual: wordRangeStrategy.rangeForUserCompletion(textView: self)
        case .none: super.rangeForUserCompletion
        }
    }

    private var completionMode: CompletionMode? = nil
    var isCompleting: Bool { completionMode != nil }

    // MARK: Editing text

    override func insertText(_ string: Any, replacementRange: NSRange) {
        // `insertText(_:replacementRange:)` accepts both NSString and NSAttributedString, so we need to unwrap this.
        guard let insertString = (string as? String) ?? (string as? NSAttributedString)?.string
        else { preconditionFailure("\(#function) called with non-string value") }

        // MARK: Wrap original implementation with completion range change tracking

        // Use cached value from the delegate instead of `NSTextView.rangeForUserCompletion` because the latter aborts marking text.
        let rangeForCompletionBeforeInserting: NSRange? = completionLifecycleDelegate?.completionPartialWordRange

        super.insertText(string, replacementRange: replacementRange)

        let rangeForCompletionAfterInserting: NSRange? = if let _ = rangeForCompletionBeforeInserting {
            // We don't call this before inserting because `NSTextView.rangeForUserCompletion` aborts marking text. But so does `insertText(_:replacementRange:)`, so afterwards, we're good.
            self.rangeForUserCompletion
        } else {
            nil
        }

        let typingDidChangeCompletionContext: Bool
        if let rangeForCompletionBeforeInserting,
            let rangeForCompletionAfterInserting {
            typingDidChangeCompletionContext = !rangeForCompletionBeforeInserting.intersects(with: rangeForCompletionAfterInserting)
        } else {
            assert(!isCompleting, "Optional unwrapping of ranges should have succeeded with an active completion session")
            typingDidChangeCompletionContext = false // Sentinel value is irrelevant, because there's no completion.
        }

        // MARK: Postconditions: control the completion UI

        if isCompleting,
           typingDidChangeCompletionContext {
            stopCompleting()
        } else {
            completionLifecycleDelegate?.continueCompleting(textView: self)

            triggerAutocompletion(fromTyping: insertString)
        }
    }

    private func stopCompleting() {
        self.completionLifecycleDelegate?.stopCompleting(textView: self)
        self.completionMode = nil
    }

    private func triggerAutocompletion(fromTyping insertString: String) {
        // Auto-completion is not supposed to replace in-progress completions.
        guard !isCompleting else { return }

        if insertString == "#" {
            if completionMode == nil {
                completionMode = .hashtag
            }
            complete(self)
        }

        if insertString == "[" {
            guard let textStorage = self.textStorage else { preconditionFailure("NSTextView should have a text storage") }
            guard self.selectedRange.length == 0 else { assertionFailure("triggerAutocompletion via insertText should not have a selection range, only insertion point location"); return }

            let insertionPoint = self.selectedRange.location
            let precedingTextLength = 2
            let precedingRange = NSRange(location: insertionPoint - precedingTextLength, length: precedingTextLength)
            if precedingRange.location >= 0 {
                let precedingText = textStorage.mutableString.substring(with: precedingRange)
                if precedingText == "[[" {
                    if completionMode == nil {
                        completionMode = .wikilink
                    }
                    complete(self)
                }
            }
        }
    }

    override func setSelectedRanges(
        _ selectedRanges: [NSValue],
        affinity: NSSelectionAffinity,
        stillSelecting stillSelectingFlag: Bool
    ) {
        super.setSelectedRanges(selectedRanges, affinity: affinity, stillSelecting: stillSelectingFlag)

        // Coalesce multiple selection change events originating during the same RunLoop iteration into 1 call (scheduled for the next run).
        // Motivation: Inserting a completion will insert the suggested partial word, which (1st change event) moves the insertion point to the end of the word, and then (2nd change event) selects the suggested partial word. Only after the 2nd event is the range going to "touch" `rangeForUserCompletion`, so we want to postpone reacting to selection changes until then. Otherwise, it would appear that the insertion point has been moved so that we want to abort the completion session.
        // Bonus: `insertText` eventually invokes `setSelectedRanges` when changing the text, so the completion lifecycle delegate hasn't updated ranges from `insertText`, yet. With this approach, we postpone reacting to selection changes until both the suggested partial word has been selected and the delegate has been updates.
        if isCompleting {
            // Do not pass a non-nil `object` parameter here, because cancelling requests will test for object equality. Passing nil at all times helps us coalesce all calls, no matter what the input parameters to `setSelectedRanges` were. (If we ever find we need to pass the parameters along, we should instead store these as private properties in the text view to avoid invoking the callback 2+ times.)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(selectedRangesDidChange(_:)), object: nil)
            self.perform(#selector(selectedRangesDidChange(_:)), with: nil, afterDelay: 0.0)
        }
    }

    @objc private func selectedRangesDidChange(
        _ object: Any? = nil
    ) {
        // Abort completion for multiple selections.
        guard selectedRanges.count == 1,
              let onlySelectedRange = selectedRanges.first as? NSRange
        else {
            stopCompleting()
            return
        }

        // Use cached value from the delegate instead of `NSTextView.rangeForUserCompletion` because the latter aborts marking text.
        guard let lastKnownRangeForCompletion = completionLifecycleDelegate?.completionPartialWordRange else { return }
        assert(isCompleting, "Inconsistency: CompletionLifecycleDelegate.completionPartialWordRange should not return non-nil while isCompleting returns false")

        let selectionChangeDidChangeCompletionContext = !(
            lastKnownRangeForCompletion.intersects(with: onlySelectedRange)  // Selection inside
            || lastKnownRangeForCompletion.endLocation == onlySelectedRange.location // Selection immediately adjacent to the right/end of the completion range
        )

        if selectionChangeDidChangeCompletionContext {
            stopCompleting()
            return
        }

        switch completionMode {
        case .manual:
            break
        case .hashtag, .wikilink:
            if lastKnownRangeForCompletion.length == 0 {
                stopCompleting()
                return
            }
        case nil:
            break
        }

    }

    override func doCommand(by selector: Selector) {
        super.doCommand(by: selector)
        completionLifecycleDelegate?.continueCompleting(textView: self)
    }

    // MARK: - Completion
    // MARK: Process callbacks

    override func complete(_ sender: Any?) {
        /// Original `isCompleting` value before potential changes to `completionMode` (which effectively turns `isCompleting` on)
        let isContinuingCompletion = self.isCompleting

        let partialWordRange: NSRange
        if self.completionMode == nil {
            let (range, mode) = detectedRangedCompletionMode()
            partialWordRange = range
            self.completionMode = mode
        } else {
            partialWordRange = self.rangeForUserCompletion
        }

        guard let textStorage else { preconditionFailure("NSTextView should have a text storage") }

        /// Unused by our approach, but required by the API; selection is reflected in the completion window directly.
        // TODO: We could use indexOfSelectedItem for restoration of selected items when typing.
        var indexOfSelectedItem: Int = -1
        let completions = self.completions(
            forPartialWordRange: partialWordRange,
            indexOfSelectedItem: &indexOfSelectedItem
        )?.map(CompletionCandidate.init(_:))

        guard let completions,
              !completions.isEmpty
        else {
            if isContinuingCompletion {
                completionLifecycleDelegate?.stopCompleting(textView: self)
            }
            if case .manual = completionMode {
                // For manual ('forced') invocation, produce error sound. Avoid beeping for the auto-completion while typing hashtags.
                NSSound.beep()
            }
            completionMode = nil
            return
        }

        completionLifecycleDelegate?.startCompleting(
            textView: self,
            completionCandidates: completions,
            forPartialWordRange: partialWordRange,
            originalString: textStorage.mutableString.substring(with: partialWordRange)
        )
    }

    /// Determines which completion mode to activate.
    ///
    /// In case of conflicting matches like `"[[#fooˇ]]"`, favors:
    ///
    /// 1. Wiki links (`"[["` prefix) over
    /// 2. Hashtags (`/#+/` prefix) over
    /// 3. Dictionary words.
    private func detectedRangedCompletionMode() -> (range: NSRange, mode: CompletionMode) {
        assert(self.completionMode == nil, "Trying to detect an applicable mode while a completion (mode) is active. This function is not designed to handle that case.")
        guard let textStorage = self.textStorage else { preconditionFailure("NSTextView should have a text storage") }

        // We could default to `hashtagRangeStrategy` because it chiefly matches a superset of `wordRangeStrategy`. But with wiki link completion candidates, we will want to escalate to favor one over the other, as wiki links aren't a superset to hashtags, and they need to be weighed against each other.
        let wikilinkRange = wikilinkRangeStrategy.rangeForUserCompletion(textView: self)
        let hashtagRange = hashtagRangeStrategy.rangeForUserCompletion(textView: self)
        let wordRange = wordRangeStrategy.rangeForUserCompletion(textView: self)

        if textStorage.mutableString.substring(with: wikilinkRange).hasPrefix("[[") {
            return (wikilinkRange, .wikilink)
        }

        if textStorage.mutableString.substring(with: hashtagRange).hasPrefix("#") {
            return (hashtagRange, .hashtag)
        }

        return (wordRange, .manual)
    }

    override func insertCompletion(_ word: String, forPartialWordRange charRange: NSRange, movement: Int, isFinal isFinishingCompletion: Bool) {
        // Closing the popover cancels completion via `insertCompletion(_, charRange: _, movement: .cancel, isFinal: true)`, but we also close the popover upon completion. To avoid accepting a completion, followed by an automatic cancel message, we need to (a) check whether we're still actively completing anything (this approach), or (b) implement reacting to the `NSPopover` closing differently.
        guard isCompleting else { return }

        // Unlike other programmatic text changes, `insertCompletion(_:forPartialWordRange:charRange:movement:isFinal:)` already calls `shouldChangeText(in:replacementString:)` before, and `didChangeText()` after inserting the completion, so we don't have to.
        if completionMode == .wikilink,
           // Behave normally on ESC to cancel (which uses charRange to put the insertion point after the previously typed text).
           NSTextMovement(rawValue: movement) != .cancel {
            // Select all of the completion candidate for wiki links, because they aren't suggested based on a common prefix like the others.
            // The UX of the default behavior would be weird: type "[[ad", then select e.g. "No Advances in Virtual Reality", it would select "No« Advances in Virtual Reality»", with the first 2 letters ("No") being different form what you typed. That's especially jarring when arrowing down through the list of completions.
            let charRangeWithoutCommonPrefix = NSRange(location: charRange.location, length: 0)
            super.insertCompletion(word, forPartialWordRange: charRangeWithoutCommonPrefix, movement: movement, isFinal: isFinishingCompletion)
        } else {
            super.insertCompletion(word, forPartialWordRange: charRange, movement: movement, isFinal: isFinishingCompletion)
        }

        if isFinishingCompletion {
            completionLifecycleDelegate?.stopCompleting(textView: self)
            completionMode = nil
        }
    }

    // MARK: Generating candidates

    override func completions(forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String]? {
        switch completionMode {
        case .hashtag:
            guard let prefix = textStorage?.mutableString.substring(with: charRange) else { return nil }
            return HashtagRepository.shared.filter { $0.hasPrefix(prefix) }
        case .wikilink:
            guard let needle = textStorage?.mutableString.substring(with: charRange).lowercased() else { return nil }
            let needleIsEmpty = needle.count == 0
            return WikilinkRepository.shared.filter { needleIsEmpty || $0.lowercased().contains(needle) }
        case .manual, nil:
            return super.completions(forPartialWordRange: charRange, indexOfSelectedItem: index)
        }
    }
}
