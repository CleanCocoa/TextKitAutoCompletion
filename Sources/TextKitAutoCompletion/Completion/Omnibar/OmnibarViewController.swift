//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import Omnibar

protocol SearchHandler: AnyObject {
    func search(for searchTerm: String, offerSuggestion: Bool)
}

class OmnibarViewController: NSViewController {
    weak var searchHandler: SearchHandler?

    lazy var omnibar = Omnibar()

    override func loadView() {
        omnibar.translatesAutoresizingMaskIntoConstraints = false
        self.view = omnibar
    }

    func display(selectedWord: CompletionCandidate) {
        omnibar.display(content: .selection(text: selectedWord.value))
    }

    func commitOmnibarContents() {
        omnibar.commit()
    }
}

extension OmnibarViewController: @preconcurrency DisplaysBestFit {
    func display(bestFit: CompletionCandidate, forSearchTerm searchTerm: String) {
        guard let suggestion = OmnibarSuggestion(bestFit: bestFit.value, forSearchTerm: searchTerm) else { return }
        omnibar.display(content: suggestion.omnibarContent)
    }
}
