//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

class CompletionViewController: NSViewController {
    lazy var candidateListViewController = CandidateListViewController()
    lazy var movementAction = MovementAction(wrapping: candidateListViewController)

    private var adapter: CompletionAdapter<NSTextView>?

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

        stackView.addArrangedSubview(candidateListViewController.view)

        candidateListViewController.selectCandidate = SelectCompletionCandidate { [weak self] selectedCandidate in
            self?.adapter?.suggestCompletion(text: selectedCandidate.value)
        }
        candidateListViewController.commitSelectedCandidate = { [weak self] selectedCandidate in
            self?.adapter?.finishCompletion(text: selectedCandidate.value)
        }
    }

    func showCompletionCandidates(_ candidates: [CompletionCandidate], in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { preconditionFailure("NSTextView should have a text storage") }
        let word = textStorage.mutableString.substring(with: textView.rangeForUserCompletion)

        candidateListViewController.display(candidates: candidates, selecting: nil)

        adapter = adapter ?? CompletionAdapter(textView: textView)
        assert(adapter?.adaptee === textView, "Reusing old adapter expects the textView to be the same")
    }

    override func cancelOperation(_ sender: Any?) {
        adapter?.cancelCompletion()
    }
}
