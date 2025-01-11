//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

class CompletionViewController: NSViewController, CandidateListViewControllerDelegate {
    lazy var candidateListViewController = CandidateListViewController()

    // Implicitly unwrapped optional used to form a self-reference in the callback during init.
    private var adapter: CompletionAdapter!

    init(textView: NSTextView) {
        super.init(nibName: nil, bundle: nil)

        self.adapter = CompletionAdapter(
            textView: textView,
            willProxyInvocation: { [unowned self] receiver, selector in
                // Dismiss the completion UI automatically if a (main menu) action is invoked on the text view.

                assert(receiver === textView)
                dispatchPrecondition(condition: .onQueue(.main))

                /// Collection of selectors that are not associated with execting or performing actions on a target, but validation.
                let nonPerformingSelectors: Set<Selector> = [
                    #selector(responds(to:)),
                    #selector(NSMenuItemValidation.validateMenuItem(_:)),
                ]
                guard !nonPerformingSelectors.contains(selector)
                else { return }

                MainActorBackport.assumeIsolated {
                    self.cancelCompletion()
                }
            })
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("\(#function) not implemented")
    }

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

        candidateListViewController.delegate = self
        candidateListViewController.selectCandidate = SelectCompletionCandidate { [weak self] selectedCandidate in
            self?.adapter.suggestCompletion(text: selectedCandidate.value)
        }
        candidateListViewController.commitSelectedCandidate = { [weak self] selectedCandidate in
            self?.adapter.finishCompletion(text: selectedCandidate.value)
        }
    }

    func show(completionCandidates: [CompletionCandidate]) {
        candidateListViewController.display(candidates: completionCandidates, selecting: nil)
    }

    func commitCandidateSelection() {
        candidateListViewController.commitSelection(self)
    }

    func cancelCompletion() {
        adapter.cancelCompletion()
    }

    override func keyDown(with event: NSEvent) {
        interpretKeyEvents([event])
    }

    // MARK: Forward key interpretations

    override func doCommand(by selector: Selector) {
        // Don't call `super`: The default implementation escalates through the responder chain until NSWindow refuses to handle it with an NSBeep.

        if self.responds(to: selector) {
            perform(selector, with: nil)
            return
        }

        switch selector {
        case #selector(moveUp(_:)),
            #selector(moveDown(_:)),
            #selector(moveToBeginningOfDocument(_:)),
            #selector(moveToEndOfDocument(_:)):
            candidateListViewController.perform(selector, with: nil)
        default:
            adapter.doCommand(by: selector)
        }
    }

    override func insertText(_ insertString: Any) {
        adapter.insertText(insertString)
    }

    // MARK: Forward main menu items

    override func supplementalTarget(forAction action: Selector, sender: Any?) -> Any? {
        if adapter.responds(to: action) {
            // Covers NSText methods: paste(_:), copy(_:), cut(_:), delete(_:); also font and styling settings
            return adapter
        } else {
            return super.supplementalTarget(forAction: action, sender: sender)
        }
    }

    // MARK: Completion shortcuts

    override func cancelOperation(_ sender: Any?) {
        cancelCompletion()
    }

    override func insertTab(_ sender: Any?) {
        if candidateListViewController.hasSelectedCompletionCandidate {
            commitCandidateSelection()
        } else {
            candidateListViewController.selectFirst()
        }
    }

    override func insertBacktab(_ sender: Any?) {
        cancelCompletion()
    }

    override func insertNewline(_ sender: Any?) {
        commitCandidateSelection()
    }
}
