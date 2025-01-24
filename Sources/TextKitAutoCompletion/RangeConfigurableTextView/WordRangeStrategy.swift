//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextBuffer

extension CharacterSet {
    static let nonComposableWordCharacters: CharacterSet = .letters
      .union(.init(charactersIn: "-_"))
      .inverted
}

/// Obtain the range for user completion by looking for words, potentially joined by hyphens, like `"long-term"`.
public struct WordRangeStrategy: RangeForUserCompletionStrategy {
    public init() {}

    public func rangeForUserCompletion(textView: NSTextView) -> NSRange {
        // Avoiding potential bridging overhead from `NSTextView.string as NSString` by accessing the un-bridged mutable string of the text storage.
        guard let nsString = textView.textStorage?.mutableString as NSString? else {
            preconditionFailure("NSTextView needs a text storage to function")
        }

        let point = textView.selectedRange().upperBound
        guard point != NSNotFound else {
            assertionFailure("NSTextView with user interaction should always have a selection or point")
            return .notFound
        }

        let rangeUpToPoint = NSRange(startLocation: 0, endLocation: point)
        let pointBeforeWord = nsString.locationUpToCharacter(
          from: .nonComposableWordCharacters,
          direction: .upstream,
          in: rangeUpToPoint
        )
        guard let pointBeforeWord else { return rangeUpToPoint }
        let wordRange = NSRange(startLocation: pointBeforeWord, endLocation: point)
        if !nsString.substring(with: wordRange).contains(where: \.isLetter) {
            return NSRange(location: point, length: 0)
        }
        return wordRange
    }
}
