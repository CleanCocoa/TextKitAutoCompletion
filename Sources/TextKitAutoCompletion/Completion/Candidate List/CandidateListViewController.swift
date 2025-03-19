//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

extension NSUserInterfaceItemIdentifier {
    static var tableCellView: NSUserInterfaceItemIdentifier { return .init(rawValue: "TKACTableCellView") }
}

@MainActor
protocol CandidateListViewControllerDelegate: NSResponder {}

/// Table view that does not even attempt to respond to key events for space bar input.
///
/// In lists of ~5000 completion candidates, even with `allowsTypeSelect`  set to false, hitting spacebar will take a noticable time (2+ seconds) before the popover ultimately is dismissed. The majority of time is spent in `-[NSTableView keyDown:]` and `-[NSTableView _typeSelectInterpretKeyEvent:]`, even when `allowsTypeSelect` is disabled.
///
/// This only happens for hitting the space bar, not for typing a letter key on the keyboard.
///
/// - 2025-02-15: `FB16503968`
fileprivate class SpaceBarTypeSelectionBypassingTableView: NSTableView {
    override func keyDown(with event: NSEvent) {
        assert(!allowsTypeSelect, "Using this fix at all assumes that we want to not type-to-select.")
        if event.charactersIgnoringModifiers == " " {
            assert(delegate is CandidateListViewController)
            (delegate as? NSResponder)?.keyDown(with: event)
            return
        } else {
            super.keyDown(with: event)
        }
    }
}

class CandidateListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    weak var delegate: CandidateListViewControllerDelegate?
    lazy var tableView: NSTableView = SpaceBarTypeSelectionBypassingTableView()

    var commitSelectedCandidate: (CompletionCandidate) -> Void = { _ in /* no op */ }
    var selectCandidate: SelectCompletionCandidate = SelectCompletionCandidate { _ in /* no op */ }

    private var completionCandidates: [CompletionCandidate] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    var hasSelectedCompletionCandidate: Bool { selectedCompletionCandidate != nil }

    var selectedCompletionCandidate: CompletionCandidate? {
        let index = tableView.selectedRow
        guard index > -1 else { return nil }
        assert(index < completionCandidates.count)
        return completionCandidates[index]
    }

    /// Cache of programmatic selections to avoid change events
    fileprivate var programmaticallySelectedRow: Int?

    override func loadView() {
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.borderType = .noBorder

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.addTableColumn(NSTableColumn(identifier: .tableCellView))
        tableView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        tableView.allowsColumnResizing = false
        tableView.allowsTypeSelect = false
        tableView.allowsEmptySelection = true
        tableView.allowsColumnSelection = false
        tableView.allowsMultipleSelection = false
        tableView.rowSizeStyle = .custom
        tableView.usesAutomaticRowHeights = true
        if #available(macOS 11.0, *) {
            tableView.style = .plain
        }
        scrollView.documentView = tableView

        // Double-click to select (in case the user tabbed/clicked into the table view).
        tableView.doubleAction = #selector(commitSelection(_:))
        tableView.target = self

        scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true

        self.view = scrollView
    }

    func display(candidates: [CompletionCandidate], selecting selectedWord: CompletionCandidate?) {

        self.completionCandidates = candidates
        self.programmaticallySelectedRow = nil

        if let selectedWord = selectedWord,
           let selectionIndex = candidates.firstIndex(of: selectedWord) {
            programmaticallySelectedRow = selectionIndex
            select(row: selectionIndex)
        }
    }

    // MARK: - Event handling

    override func keyDown(with event: NSEvent) {
        delegate?.interpretKeyEvents([event])
    }

    override func insertNewline(_ sender: Any?) {
        assertionFailure("We expect return/enter to be handled by the delegate's interpretation of key events")
        commitSelection(sender)
    }

    @IBAction func commitSelection(_ sender: Any?) {
        guard let selectedCompletionCandidate else { return }
        self.commitSelectedCandidate(selectedCompletionCandidate)
    }

    // MARK: - Table View Delegate

    func numberOfRows(in tableView: NSTableView) -> Int {
        return completionCandidates.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return completionCandidates[row]
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        rowView.clipsToBounds = true
        rowView.wantsLayer = true
        rowView.layer!.cornerRadius = 6  // Experimental value for 4pt inset in popover; 7 also looks okay but suspiciously is an odd number.
        rowView.layer!.masksToBounds = true
        return rowView
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = NSTableCellView()
        cellView.identifier = tableColumn?.identifier

        let textField = NSTextField()
        textField.stringValue = completionCandidates[row].value
        textField.isBordered = false
        textField.isEditable = false
        textField.drawsBackground = false
        textField.translatesAutoresizingMaskIntoConstraints = false

        cellView.textField = textField
        cellView.addSubview(textField)
        NSLayoutConstraint.activate([
            cellView.leadingAnchor.constraint(equalTo: textField.leadingAnchor, constant: 0),
            cellView.trailingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 0),
            cellView.topAnchor.constraint(equalTo: textField.topAnchor, constant: -4),
            cellView.bottomAnchor.constraint(equalTo: textField.bottomAnchor, constant: 4),
        ])

        return cellView
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }

        // Skip programmatic changes
        guard tableView.selectedRow != programmaticallySelectedRow else { return }
        guard let selectedCompletionCandidate else { return }
        selectCandidate(candidate: selectedCompletionCandidate)
    }
}

extension CandidateListViewController {
    func commitSelectionOrSuggestFirst() {
        if hasSelectedCompletionCandidate {
            commitSelection(nil)
        } else {
            selectFirst()
        }
    }

    func commitSelectionOrOnlyCandidateOrCancel() {
        if hasSelectedCompletionCandidate {
            commitSelection(nil)
        } else if completionCandidates.count == 1 {
            // Select only candidate
            selectFirst()
            commitSelection(nil)
        } else {
            delegate?.cancelOperation(self)
        }
    }
}

extension CandidateListViewController {
    func selectFirst() {
        select(row: completionCandidates.indices.first ?? -1)
    }

    func selectLast() {
        select(row: completionCandidates.indices.last ?? -1)
    }

    func selectPrevious() {
        guard let firstRow = completionCandidates.indices.first,
              tableView.selectedRow > firstRow
        else { return }
        select(row: tableView.selectedRow - 1)
    }

    func selectNext() {
        guard let lastRow = completionCandidates.indices.last,
              tableView.selectedRow < lastRow
        else { return }
        select(row: tableView.selectedRow + 1)
    }

    private func select(row: Int) {
        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        tableView.scrollRowToVisible(row)
    }
}

extension CandidateListViewController {
    override func moveUp(_ sender: Any?) {
        selectPrevious()
    }

    override func moveDown(_ sender: Any?) {
        selectNext()
    }

    override func moveToBeginningOfDocument(_ sender: Any?) {
        selectFirst()
    }

    override func moveToEndOfDocument(_ sender: Any?) {
        selectLast()
    }
}
