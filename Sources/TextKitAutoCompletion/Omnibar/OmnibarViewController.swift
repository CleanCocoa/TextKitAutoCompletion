//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import Omnibar

protocol SearchHandler: AnyObject {
    func search(for searchTerm: String, offerSuggestion: Bool)
}

protocol SelectsResult: AnyObject {
    func selectNext()
    func selectPrevious()
}

class OmnibarViewController: NSViewController {
    weak var searchHandler: SearchHandler?
    weak var selectionHandler: SelectsResult?

    lazy var omnibar = Omnibar()
    weak var delegate: OmnibarDelegate? {
        get { omnibar.omnibarDelegate }
        set { omnibar.omnibarDelegate = newValue }
    }

    override func loadView() {
        omnibar.translatesAutoresizingMaskIntoConstraints = false
        self.view = omnibar
    }
}

extension OmnibarViewController: @preconcurrency SelectsWordFromSuggestions {
    func select(word: Word) {
        omnibar.display(content: .selection(text: word))
    }
}

extension OmnibarViewController: @preconcurrency DisplaysSuggestion {
    func display(bestFit: String, forSearchTerm searchTerm: String) {
        guard let suggestion = Suggestion(bestFit: bestFit, forSearchTerm: searchTerm) else { return }

        omnibar.display(content: suggestion.omnibarContent)
    }
}
