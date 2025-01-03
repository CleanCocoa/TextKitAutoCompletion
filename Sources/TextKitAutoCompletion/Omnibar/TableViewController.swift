//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

protocol SelectsWord: AnyObject {
    func select(word: Word)
}

extension NSUserInterfaceItemIdentifier {
    static var tableCellView: NSUserInterfaceItemIdentifier { return .init(rawValue: "ExTableCellView") }
}

class TableViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, @preconcurrency DisplaysWords, @preconcurrency SelectsResult {

    lazy var tableView = NSTableView()

    weak var wordSelector: SelectsWord?
    
    private var words: [String] = [] {
        didSet {
            tableView.reloadData()
        }
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

        scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true

        self.view = scrollView
    }

    func display(words: [Word], selecting selectedWord: Word?) {

        self.words = words
        self.programmaticallySelectedRow = nil

        if let selectedWord = selectedWord,
           let selectionIndex = words.firstIndex(of: selectedWord) {
            programmaticallySelectedRow = selectionIndex
            select(row: selectionIndex)
        }
    }

    // MARK: - Table View Contents

    func numberOfRows(in tableView: NSTableView) -> Int {
        return words.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return words[row]
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = NSTableCellView()
        cellView.identifier = tableColumn?.identifier

        let textField = NSTextField()
        textField.stringValue = words[row]
        textField.isBordered = false
        textField.isEditable = false
        textField.drawsBackground = false
        textField.translatesAutoresizingMaskIntoConstraints = false

        cellView.textField = textField
        cellView.addSubview(textField)
        NSLayoutConstraint.activate([
            cellView.leadingAnchor.constraint(equalTo: textField.leadingAnchor, constant: 4),
            cellView.trailingAnchor.constraint(equalTo: textField.leadingAnchor, constant: -4),
            cellView.topAnchor.constraint(equalTo: textField.topAnchor, constant: -4),
            cellView.bottomAnchor.constraint(equalTo: textField.bottomAnchor, constant: 4),
        ])

        return cellView
    }


    // MARK: Table View Selection

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }

        // Skip programmatic changes
        guard tableView.selectedRow != programmaticallySelectedRow else { return }

        let word = words[tableView.selectedRow]
        wordSelector?.select(word: word)
    }

    func selectPrevious() {
        guard tableView.selectedRow > 0 else { return }
        select(row: tableView.selectedRow - 1)
    }

    func selectNext() {
        guard tableView.selectedRow < words.count else { return }
        select(row: tableView.selectedRow + 1)
    }

    private func select(row: Int) {
        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        tableView.scrollRowToVisible(row)
    }
}
