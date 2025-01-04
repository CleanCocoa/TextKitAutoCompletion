//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import Omnibar

public class CompletionPopoverController: NSViewController {
    lazy var omnibarController = OmnibarViewController()
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

        omnibarController.delegate = self
        omnibarController.searchHandler = filterService
        omnibarController.selectionHandler = tableViewController
        tableViewController.wordSelector = omnibarController
    }

    public func showCompletions(_ completions: [String]) {
        filterService.updateWords(completions)
        filterService.displayAll()
    }

    private weak var textKitAutoCompletion: TextKitAutoCompletion?

    public func drive(textKitAutoCompletion: any TextKitAutoCompletion) {
        self.textKitAutoCompletion = textKitAutoCompletion
    }
}

// TODO: Forward selectionIndex to TextKitAutoCompletion

extension CompletionPopoverController: @preconcurrency OmnibarDelegate {
    public func omnibarDidCancelOperation(_ omnibar: Omnibar) {
        assert(textKitAutoCompletion != nil)
        guard let textKitAutoCompletion else { return }
        let originalText = "x" // TODO: Store this during the completion session
        let originalWordRange = NSRange(location: 0, length: 1)  // TODO: Store this during the completion session
        textKitAutoCompletion.insertCompletion(originalText, forPartialWordRange: originalWordRange, movement: .cancel, isFinal: true)
    }

    public func omnibar(
        _ omnibar: Omnibar,
        contentChange: OmnibarContentChange,
        method: ChangeMethod
    ) {
        assert(textKitAutoCompletion != nil)
        omnibarController.searchHandler?.search(
            for: contentChange.text,
            offerSuggestion: method == .appending)
    }

    public func omnibarSelectNext(_ omnibar: Omnibar) {
        assert(textKitAutoCompletion != nil)
        omnibarController.selectionHandler?.selectNext()
    }

    public func omnibarSelectPrevious(_ omnibar: Omnibar) {
        assert(textKitAutoCompletion != nil)
        omnibarController.selectionHandler?.selectPrevious()
    }

    public func omnibar(_ omnibar: Omnibar, commit text: String) {
        assert(textKitAutoCompletion != nil)
        guard let textKitAutoCompletion else { return }
        let originalWordRange = NSRange(location: 0, length: 1)  // TODO: Store this during the completion session
        textKitAutoCompletion.insertCompletion(text, forPartialWordRange: originalWordRange, movement: .return, isFinal: true)
    }
}
