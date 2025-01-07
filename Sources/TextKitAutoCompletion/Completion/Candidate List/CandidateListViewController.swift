//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

extension NSUserInterfaceItemIdentifier {
    static var tableCellView: NSUserInterfaceItemIdentifier { return .init(rawValue: "TKACTableCellView") }
}

class CandidateListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, @preconcurrency DisplaysCompletionCandidates {

    lazy var tableView = NSTableView()

    var commitSelectedCandidate: (CompletionCandidate) -> Void = { _ in /* no op */ }
    var selectCandidate: SelectCompletionCandidate = SelectCompletionCandidate { _ in /* no op */ }

    private var completionCandidates: [CompletionCandidate] = [] {
        didSet {
            tableView.reloadData()
        }
    }

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
        interpretKeyEvents([event])
    }

    override func insertNewline(_ sender: Any?) {
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
            cellView.leadingAnchor.constraint(equalTo: textField.leadingAnchor, constant: 4),
            cellView.trailingAnchor.constraint(equalTo: textField.trailingAnchor, constant: -4),
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
        let candidate = completionCandidates[tableView.selectedRow]
        selectCandidate(candidate: candidate)
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
        guard tableView.selectedRow > 0 else { return }
        select(row: tableView.selectedRow - 1)
    }

    func selectNext() {
        guard tableView.selectedRow < completionCandidates.count else { return }
        select(row: tableView.selectedRow + 1)
    }

    private func select(row: Int) {
        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        tableView.scrollRowToVisible(row)
    }
}
