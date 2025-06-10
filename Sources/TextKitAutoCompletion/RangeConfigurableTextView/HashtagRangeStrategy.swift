//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

private let hash = "#"
private let characterSetExcludingHash = CharacterSet(charactersIn: hash).inverted

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

    public func rangeForUserCompletion(textView: NSTextView) -> MaybeRange {
        // Avoiding potential bridging overhead from  `NSTextView.string as NSString` by accessing the un-bridged mutable string of the text storage.
        guard let nsString = textView.textStorage?.mutableString as NSString? else {
            preconditionFailure("NSTextView needs a text storage to function")
        }

        guard case .range(let baseRange) = base.rangeForUserCompletion(textView: textView) else { return nil }
        guard baseRange != .notFound else { return nil }

        let rangeUpToPoint = NSRange(startLocation: 0, endLocation: baseRange.location)

        // Hashes should be right before `baseRange`, otherwise the strategy fails.
        guard rangeUpToPoint.length > 0 else { return nil }
        let characterBeforePoint = nsString.substring(with: NSRange(location: baseRange.location - 1, length: 1))
        assert(characterBeforePoint.count == 1)
        guard characterBeforePoint == hash else { return nil }

        // Skip over hashes before point.
        let pointBeforeHashes = nsString.locationUpToCharacter(
            from: characterSetExcludingHash,
            direction: .upstream,
            in: rangeUpToPoint
        ) ?? 0

        // FIXME: locationUpToCharacter should *exclude* that point
        guard pointBeforeHashes != baseRange.location else { return .range(baseRange) }

        if isMatchingFirstHash {
            let rangeIncludingHashes = NSRange(
                startLocation: pointBeforeHashes,
                endLocation: baseRange.endLocation
            )
            return .range(rangeIncludingHashes)
        } else {
            let pointAfterFirstHash = pointBeforeHashes + 1
            let rangeWithoutFirstHash = NSRange(
                startLocation: pointAfterFirstHash,
                endLocation: baseRange.endLocation
            )
            return .range(rangeWithoutFirstHash)
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
