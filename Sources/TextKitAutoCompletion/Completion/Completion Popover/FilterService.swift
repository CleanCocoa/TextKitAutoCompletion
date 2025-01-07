//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Dispatch

protocol DisplaysCompletionCandidates {
    func display(candidates: [CompletionCandidate], selecting selectedSuggestion: CompletionCandidate?)
}

protocol DisplaysBestFit {
    func display(bestFit: CompletionCandidate, forSearchTerm searchTerm: String)
}

final class FilterService: @unchecked Sendable {
    fileprivate static let filterQueue = DispatchQueue(
        label: "filter-queue",
        qos: .userInitiated,
        attributes: .concurrent,
        autoreleaseFrequency: .inherit,
        target: nil
    )

    let candidatesDisplay: DisplaysCompletionCandidates
    let bestFitDisplay: DisplaysBestFit

    private var candidates: [CompletionCandidate] = []

    fileprivate var pendingRequest: Cancellable<FilterResults>?

    init(
        candidatesDisplay: DisplaysCompletionCandidates,
        suggestionDisplay: DisplaysBestFit
    ) {
        self.candidatesDisplay = candidatesDisplay
        self.bestFitDisplay = suggestionDisplay
    }

    func update(candidates: [CompletionCandidate]) {
        self.candidates = candidates
    }
}

extension FilterService: SearchHandler {
    func displayAll() {
        search(for: "", offerSuggestion: false)
    }

    func search(for searchTerm: String, offerSuggestion: Bool) {
        let newRequest = Cancellable<FilterResults> { [unowned self] result in
            // delayThread() // uncomment to reveal timing problems
            DispatchQueue.main.async {
                if offerSuggestion,
                   let bestFit = result.bestMatch
                {
                    self.bestFitDisplay.display(bestFit: bestFit, forSearchTerm: searchTerm)
                    self.candidatesDisplay.display(candidates: result.candidates, selecting: bestFit)
                } else {
                    self.candidatesDisplay.display(candidates: result.candidates, selecting: nil)
                }
            }
        }

        pendingRequest?.cancel()
        pendingRequest = newRequest

        FilterService.filterQueue.async { [candidates] in
            newRequest.handler(result: .init(
                fromCandidates: candidates,
                searchTerm: searchTerm
            ))
        }
    }
}


struct FilterResults {
    let candidates: [CompletionCandidate]
    let bestMatch: CompletionCandidate?

    init(
        candidates: [CompletionCandidate],
        bestMatch: CompletionCandidate? = nil
    ) {
        self.candidates = candidates
        self.bestMatch = bestMatch
    }
}

extension FilterResults {
    init(
        fromCandidates candidates: [CompletionCandidate],
        searchTerm: String
    ) {
        guard !searchTerm.isEmpty else {
            self.init(candidates: candidates, bestMatch: nil)
            return
        }

        let filteredCandidates = candidates.filter { $0.contains(searchTerm) }
        let bestMatch = filteredCandidates.first { $0.startsWith(searchTerm) }

        self.init(
            candidates: filteredCandidates,
            bestMatch: bestMatch
        )
    }
}
