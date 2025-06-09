//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

/// Obtain the range for user completion ignoring opening double brackets ("`[[`") as a marker of the wikilink.
public struct WikilinkRangeStrategy<Base>: RangeForUserCompletionStrategy
where Base: RangeForUserCompletionStrategy {
    /// Wrapped range matching strategy to which wikilink detection is added.
    public let base: Base

    /// Whether to include the opening and closing brackets ("`[[`" and "`]]`", respectively) in the matched ranges.
    public let isIncludingBracketsInMatchedRange: Bool

    /// - Parameters:
    ///   - base: Completion strategy to extend with wiki link detection.
    public init(
        wrapping base: Base,
        includingBracketsInMatchedRange: Bool = false
    ) {
        self.base = base
        self.isIncludingBracketsInMatchedRange = includingBracketsInMatchedRange
    }

    public func rangeForUserCompletion(textView: NSTextView) -> NSRange {
        // Avoiding potential bridging overhead from  `NSTextView.string as NSString` by accessing the un-bridged mutable string of the text storage.
        guard let nsString = textView.textStorage?.mutableString as NSString? else {
            preconditionFailure("NSTextView needs a text storage to function")
        }

        let baseRange = base.rangeForUserCompletion(textView: textView)
        guard baseRange != .notFound else { return baseRange }
        let rangeUpToPoint = NSRange(startLocation: 0, endLocation: baseRange.location)

        /// The two latest character sequences that were scanned.
        var scannedTuple: (String?, String?) = (nil, nil)

        /// Push `string` into `scannedTuple`, discarding the trailing element.
        func scan(_ string: String) {
            scannedTuple = (string, scannedTuple.0)
        }

        var pointBeforeOpeningBrackets: Int?
        nsString.enumerateSubstrings(
            in: rangeUpToPoint,
            options: [.byComposedCharacterSequences, .reverse],
            using: { characterSequence, characterSequenceRange, enclosingRange, stop in
                guard let characterSequence else {
                    assertionFailure("enumerateSubstring should provide matched substring, but may fail when mis-configured with .substringNotRequired")
                    stop.pointee = true
                    return
                }

                scan(characterSequence)
                
                if scannedTuple == ("[", "[") {
                    // Unlike `NSString.locationUpToCharacter` used for hashtag matching (which discards the match itself), we want to search upstream and find the innermost "[[" sequence, including the matched 2nd "[".
                    pointBeforeOpeningBrackets = characterSequenceRange.location
                    stop.pointee = true
                }
        })

        guard let pointBeforeOpeningBrackets else { return baseRange }

        return NSRange(
            startLocation: pointBeforeOpeningBrackets
                + (isIncludingBracketsInMatchedRange ? 0 : 2),
            endLocation: baseRange.endLocation
        )
    }
}
