//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import Omnibar

public class CompletionPopoverController: NSViewController {
    lazy var omnibarController = OmnibarController()
    lazy var tableViewController = TableViewController()
    lazy var filterService = FilterService(
        suggestionDisplay: self.omnibarController,
        wordDisplay: self.tableViewController
    )

    public override func loadView() {
        // Do not call super as we're assembling the view programmatically.

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.edgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
        stackView.spacing = 10
        stackView.alignment = .leading
        stackView.distribution = .fill
        self.view = stackView

        stackView.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true

        stackView.addArrangedSubview(omnibarController.view)
        stackView.addArrangedSubview(tableViewController.view)

        omnibarController.searchHandler = filterService
        omnibarController.selectionHandler = tableViewController
        tableViewController.wordSelector = omnibarController
    }

    public func showCompletions(_ completions: [String]) {
        filterService.updateWords(completions)
        filterService.displayAll()
    }
}
