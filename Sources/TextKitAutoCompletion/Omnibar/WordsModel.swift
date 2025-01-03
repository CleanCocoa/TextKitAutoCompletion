//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

public typealias Word = String

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

    func filtered(searchTerm: String, result: (FilterResults) -> Void) {
        guard !searchTerm.isEmpty else {
            result(FilterResults(words: words))
            return
        }

        let filteredWords = filter(haystack: words, searchTerm: searchTerm)
        let bestMatch = bestFit(haystack: filteredWords, needleStartingWith: searchTerm)

        result(FilterResults(
            words: filteredWords,
            bestMatch: bestMatch))
    }
}

func containsAll(_ searchWords: [String]) -> (Word) -> Bool {
    return { word in
        let word = word.lowercased()
        for searchWord in searchWords {
            if !word.contains(searchWord) { return false }
        }
        return true
    }
}

func bestFit(haystack: [Word], needleStartingWith searchTerm: String) -> Word? {
    guard !searchTerm.isEmpty else { return nil }

    return haystack.first { $0.lowercased().hasPrefix(searchTerm.lowercased()) }
}

func filter(haystack: [Word], searchTerm: String) -> [Word] {
    let searchWords = searchTerm.lowercased().components(separatedBy: .whitespacesAndNewlines)
    let filtered = haystack.filter(containsAll(searchWords))

    return filtered
}
