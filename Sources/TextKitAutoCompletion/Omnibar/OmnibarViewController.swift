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
}

extension OmnibarViewController {
    func display(selectedWord: Word) {
        omnibar.display(content: .selection(text: selectedWord))
    }
}

extension OmnibarViewController: @preconcurrency DisplaysSuggestion {
    func display(bestFit: String, forSearchTerm searchTerm: String) {
        guard let suggestion = Suggestion(bestFit: bestFit, forSearchTerm: searchTerm) else { return }

        omnibar.display(content: suggestion.omnibarContent)
    }
}
