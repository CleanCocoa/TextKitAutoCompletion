//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import Omnibar

class CompletionViewController: NSViewController {
    lazy var omnibarController = OmnibarViewController()
    lazy var candidateListViewController = CandidateListViewController()
    lazy var filterService = FilterService(
        candidatesDisplay: candidateListViewController,
        suggestionDisplay: omnibarController
    )

    private var adapter: OmnibarTextKitAutoCompletionAdapter<NSTextView>?

    override func loadView() {
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
        stackView.addArrangedSubview(candidateListViewController.view)

        omnibarController.omnibar.omnibarContentChangeDelegate = self
        omnibarController.omnibar.moveFromOmnibar = MoveFromOmnibar(wrapping: candidateListViewController)
        omnibarController.searchHandler = filterService

        candidateListViewController.selectCandidate = SelectCompletionCandidate { [weak omnibarController] selectedCandidate in
            omnibarController?.display(selectedWord: selectedCandidate)
        }
        candidateListViewController.commitSelectedCandidate = { [weak self] selectedCandidate in
            self?.adapter?.finishCompletion(text: selectedCandidate.value)
        }
    }

    func showCompletionCandidates(_ candidates: [CompletionCandidate], in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { preconditionFailure("NSTextView should have a text storage") }
        let word = textStorage.mutableString.substring(with: textView.rangeForUserCompletion)

        filterService.update(candidates: candidates)
        filterService.displayAll()
        adapter = OmnibarTextKitAutoCompletionAdapter(textView: textView)
        omnibarController.omnibar.display(content: .prefix(text: word))
    }

    override func cancelOperation(_ sender: Any?) {
        adapter?.cancelCompletion()
    }
}

extension CompletionViewController: @preconcurrency OmnibarContentChangeDelegate {
    func omnibarDidCancelOperation(_ omnibar: Omnibar) {
        adapter?.omnibarDidCancelOperation(omnibar)
    }

    func omnibar(
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

    func omnibar(_ omnibar: Omnibar, commit text: String) {
        adapter?.omnibar(omnibar, commit: text)
    }
}
