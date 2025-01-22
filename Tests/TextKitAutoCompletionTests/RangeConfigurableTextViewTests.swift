//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Testing
@testable import TextKitAutoCompletion
import DeclarativeTextKit
import DeclarativeTextKitTesting
import AppKit

@MainActor
@Suite("rangeForUserCompletion")
struct RangeConfigurableTextViewTests {
    let textView: RangeConfigurableTextView
    let buffer: NSTextViewBuffer

    init() {
        let textView = RangeConfigurableTextView(usingTextLayoutManager: false)
        self.textView = textView
        self.buffer = NSTextViewBuffer(textView: textView)
    }

    func with(
      buffer value: String,
      `do` block: (_ buffer: NSTextViewBuffer) throws -> Void
    ) throws {
        try change(buffer: buffer, to: value)
        try block(buffer)
    }

    @Test func test() throws {
        try with(buffer: "Heˇllo") { buffer in
            #expect(buffer == "Heˇllo")
        }
    }
}
