//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Dispatch

protocol DisplaysCompletionCandidates {
    func display(candidates: [CompletionCandidate], selecting selectedSuggestion: CompletionCandidate?)
}

protocol DisplaysBestFit {
    func display(bestFit: CompletionCandidate, forSearchTerm searchTerm: String)
}

final class FilterService: @unchecked Sendable {
    let candidatesDisplay: DisplaysCompletionCandidates
    let bestFitDisplay: DisplaysBestFit

    init(
        candidatesDisplay: DisplaysCompletionCandidates,
        suggestionDisplay: DisplaysBestFit
    ) {
        self.candidatesDisplay = candidatesDisplay
        self.bestFitDisplay = suggestionDisplay
    }

    lazy var viewModel = CompletionCandidatesModel()
    lazy var filterQueue: DispatchQueue = DispatchQueue(
        label: "filter-queue",
        qos: .userInitiated,
        attributes: .concurrent,
        autoreleaseFrequency: .inherit,
        target: nil
    )

    fileprivate var pendingRequest: Cancellable<FilterResults>?

    func updateWords(_ words: [CompletionCandidate]) {
        viewModel.candidates = words
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

        filterQueue.async {
            self.viewModel.filtered(searchTerm: searchTerm, result: newRequest.handler)
        }
    }
}
