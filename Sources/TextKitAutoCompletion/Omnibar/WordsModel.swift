//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

public struct Word: Equatable, Sendable {
    public let value: String

    public init(value: String) {
        self.value = value
    }

    func startsWith(_ prefix: String) -> Bool {
        return value.hasPrefix(prefix, options: .caseInsensitive)
    }

    func contains(_ substring: String) -> Bool {
        return value.range(of: substring, options: .caseInsensitive) != nil
    }
}

struct FilterResults {
    let words: [Word]
    let bestMatch: Word?

    init(words: [Word], bestMatch: Word? = nil) {
        self.words = words
        self.bestMatch = bestMatch
    }
}

struct WordsModel: Sendable {
    var words: [Word]

    init(words: [Word] = []) {
        self.words = words
    }

    func filtered(
        searchTerm: String,
        result: (FilterResults) -> Void
    ) {
        guard !searchTerm.isEmpty else {
            result(FilterResults(words: words))
            return
        }

        let filteredWords = words.filter { $0.contains(searchTerm) }
        let bestMatch = filteredWords.first { $0.startsWith(searchTerm) }

        result(
            FilterResults(
                words: filteredWords,
                bestMatch: bestMatch
            )
        )
    }
}

extension String {
    fileprivate func hasPrefix(
        _ prefix: String,
        options: CompareOptions
    ) -> Bool {
        guard let matchRange = self.range(of: prefix, options: options.union(.anchored))
        else { return false }
        assert(matchRange.lowerBound == self.startIndex, "Anchored range search should guarantee that the match starts at startIndex, not somewhere in the middle")
        return true
    }
}
