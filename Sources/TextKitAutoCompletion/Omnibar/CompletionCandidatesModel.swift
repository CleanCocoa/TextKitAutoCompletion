//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

struct FilterResults {
    let candidates: [CompletionCandidate]
    let bestMatch: CompletionCandidate?

    init(candidates: [CompletionCandidate], bestMatch: CompletionCandidate? = nil) {
        self.candidates = candidates
        self.bestMatch = bestMatch
    }
}

struct CompletionCandidatesModel: Sendable {
    var candidates: [CompletionCandidate]

    init(candidates: [CompletionCandidate] = []) {
        self.candidates = candidates
    }

    func filtered(
        searchTerm: String,
        result: (FilterResults) -> Void
    ) {
        guard !searchTerm.isEmpty else {
            result(FilterResults(candidates: candidates))
            return
        }

        let filteredCandidates = candidates.filter { $0.contains(searchTerm) }
        let bestMatch = filteredCandidates.first { $0.startsWith(searchTerm) }

        result(
            FilterResults(
                candidates: filteredCandidates,
                bestMatch: bestMatch
            )
        )
    }
}
