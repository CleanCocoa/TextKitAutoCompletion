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

    private var adapter: OmnibarTextKitAutoCompletionAdapter<NSTextView>?

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

        omnibarController.omnibar.omnibarContentChangeDelegate = self
        omnibarController.omnibar.moveFromOmnibar = MoveFromOmnibar(wrapping: tableViewController)
        omnibarController.searchHandler = filterService
        tableViewController.selectWord = SelectWord { [weak omnibarController] selectedWord in
            omnibarController?.display(selectedWord: selectedWord)
        }
    }

    public func showCompletions(_ completions: [String], in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { preconditionFailure("NSTextView should have a text storage") }
        let word = textStorage.mutableString.substring(with: textView.rangeForUserCompletion)

        filterService.updateWords(completions)
        filterService.displayAll()
        adapter = OmnibarTextKitAutoCompletionAdapter(textView: textView)
        omnibarController.omnibar.display(content: .prefix(text: word))
    }
}

extension CompletionPopoverController: @preconcurrency OmnibarContentChangeDelegate {
    public func omnibarDidCancelOperation(_ omnibar: Omnibar) {
        adapter?.omnibarDidCancelOperation(omnibar)
    }

    public func omnibar(
        _ omnibar: Omnibar,
        didChangeContent contentChange: OmnibarContentChange,
        method: ChangeMethod
    ) {
        adapter?.omnibar(omnibar, didChangeContent: contentChange, method: method)
        guard method != .programmaticReplacement else { return }
        omnibarController.searchHandler?.search(
            for: contentChange.text,
            offerSuggestion: method == .appending)
    }

    public func omnibar(_ omnibar: Omnibar, commit text: String) {
        adapter?.omnibar(omnibar, commit: text)
    }
}
