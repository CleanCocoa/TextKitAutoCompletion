//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextViewProxy

class CompletionViewController: NSViewController, CandidateListViewControllerDelegate, TextViewProxyDelegate {
    lazy var candidateListViewController = CandidateListViewController()

    private let adapter: CompletionAdapter
    var completionPartialWordRange: NSRange { adapter.partialWordRange }

    init(textView: NSTextView) {
        self.adapter = CompletionAdapter(textView: textView)

        super.init(nibName: nil, bundle: nil)

        self.adapter.proxyDelegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("\(#function) not implemented")
    }

    override func loadView() {
        // Do not call super as we're assembling the view programmatically.

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.edgeInsets = .init(top: 4, left: 4, bottom: 4, right: 4)
        stackView.spacing = 0
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

    func show(
        completionCandidates: [CompletionCandidate],
        forPartialWordRange partialWordRange: NSRange,
        originalString: String
    ) {
        candidateListViewController.display(candidates: completionCandidates, selecting: nil)
        adapter.update(originalString: originalString, partialWordRange: partialWordRange)
    }

    func commitCandidateSelection() {
        candidateListViewController.commitSelection(self)
    }

    func cancelCompletion() {
        adapter.cancelCompletion()
    }

    override func keyDown(with event: NSEvent) {
        assertionFailure("CompletionViewController's keyDown is not expected to be called at the moment; subview components usually take care of this.")
        interpretKeyEvents([event])
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        return super.performKeyEquivalent(with: event)
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

    nonisolated func proxiedTextView(
        _ receiver: NSTextView,
        willInvokeSelector selector: Selector
    ) {
        let nonCancelingSelectors: Set<Selector> = [
            // Selectors that are not associated with performing actions on a target, but validation.
            #selector(responds(to:)),
            #selector(NSMenuItemValidation.validateMenuItem(_:)),
            // Selectors that edit the text so that completion may continue.
            #selector(NSStandardKeyBindingResponding.deleteBackward(_:)),
            #selector(NSStandardKeyBindingResponding.deleteBackwardByDecomposingPreviousCharacter(_:)),
            #selector(NSStandardKeyBindingResponding.deleteWordBackward(_:)),
        ]
        guard !nonCancelingSelectors.contains(selector)
        else { return }

        // Dismiss the completion UI automatically if a (main menu) action is invoked on the text view.
        dispatchPrecondition(condition: .onQueue(.main))
        MainActorBackport.assumeIsolated {
            self.cancelCompletion()
        }
    }

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
