//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

/// Obtain the range for user completion ignoring a leading pound sign/hash ("`#`") as a marker of the hashtag.
///
/// With ``isMatchingFirstHash`` set to `true`, skip the first hash but include others: multiple hashes are permitted and may denote a difference in the tag labels, like "`###triplehash`" being different from "`#triplehash`". Treating both as "`triplehash`" would be unexpected.
public struct HashtagRangeStrategy<Base>: RangeForUserCompletionStrategy
  where Base: RangeForUserCompletionStrategy {
    /// Whether ``rangeForUserCompletion(textView:)`` should include the literal "`#`".
    public let isMatchingFirstHash: Bool

    /// Wrapped range matching strategy to which hashtag detection is added.
    public let base: Base

    /// - Parameters:
    ///   - base: Completion strategy to extend with hashtag detection.
    ///   - isMatchingFirstHash: Whether ``rangeForUserCompletion(textView:)`` should include the literal "`#`". Should be `true` if your completion candidates include the hash, like "`#hashtag". Set to `false` if the hash is stripped from candidates, like "`hashtag`". A mismatch here will result in completions inserting superfluous hashes.
    public init(
      wrapping base: Base,
      isMatchingFirstHash: Bool = false
    ) {
        self.base = base
        self.isMatchingFirstHash = isMatchingFirstHash
    }

    public func rangeForUserCompletion(textView: NSTextView) -> NSRange {
        // Avoiding potential bridging overhead from  `NSTextView.string as NSString` by accessing the un-bridged mutable string of the text storage.
        guard let nsString = textView.textStorage?.mutableString as NSString? else {
            preconditionFailure("NSTextView needs a text storage to function")
        }

        let baseRange = base.rangeForUserCompletion(textView: textView)
        guard baseRange != .notFound else { return baseRange }

        let rangeUpToPoint = NSRange(startLocation: 0, endLocation: baseRange.location)

        let pointBeforeHashes = nsString.locationUpToCharacter(
            from: CharacterSet(charactersIn: "#").inverted,
            direction: .upstream,
            in: rangeUpToPoint
        ) ?? 0

        // FIXME: locationUpToCharacter should *exclude* that point
        guard pointBeforeHashes != baseRange.location else { return baseRange }

        if isMatchingFirstHash {
            let rangeIncludingHashes = NSRange(
              startLocation: pointBeforeHashes,
              endLocation: baseRange.endLocation
            )
            return rangeIncludingHashes
        } else {
            let pointAfterFirstHash = pointBeforeHashes + 1
            let rangeWithoutFirstHash = NSRange(
              startLocation: pointAfterFirstHash,
              endLocation: baseRange.endLocation
            )
            return rangeWithoutFirstHash
        }
    }
}

extension HashtagRangeStrategy where Base == TextViewDefaultRangeStrategy {
    /// Create a new ``HashtagRangeStrategy`` with the ``TextViewDefaultRangeStrategy`` as base.
    /// Parameters:
    ///   - isMatchingFirstHash: Whether ``rangeForUserCompletion(textView:)`` should include the literal "`#`". Should be `true` if your completion candidates include the hash, like "`#hashtag". Set to `false` if the hash is stripped from candidates, like "`hashtag`". A mismatch here will result in completions inserting superfluous hashes.
    public init(isMatchingFirstHash: Bool) {
        self.init(
          wrapping: .init(),
          isMatchingFirstHash: isMatchingFirstHash
        )
    }
}
