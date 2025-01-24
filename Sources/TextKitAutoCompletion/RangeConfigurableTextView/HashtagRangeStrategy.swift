//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

/// Obtain the range for user completion ignoring a leading pound sign/hash ("`#`") as a marker of the hashtag.
///
/// We only skip the first hash but include others because hashes are permitted in the tag labels, like "`###triplehash`" or "`#hash#tag`".
public struct HashtagRangeStrategy<Base>: RangeForUserCompletionStrategy
  where Base: RangeForUserCompletionStrategy {
    public let base: Base

    public init(wrapping base: Base) {
        self.base = base
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

        let pointAfterFirstHash = pointBeforeHashes + 1
        let rangeWitoutFirstHash = NSRange(
          startLocation: pointAfterFirstHash,
          endLocation: baseRange.endLocation
        )

        return rangeWitoutFirstHash
    }
}

extension HashtagRangeStrategy where Base == TextViewDefaultRangeStrategy {
    /// Convenience initializer to create a new ``HashtagRangeStrategy`` with the ``TextViewDefaultRangeStrategy`` as base.
    public init() {
        self.init(wrapping: .init())
    }
}
