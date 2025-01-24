//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Testing
import TextKitAutoCompletion
import TextBuffer
import TextBufferTesting
import AppKit

@MainActor
@Suite
struct HashtagRangeStrategyTests: BufferTestsBase {
    let buffer: NSTextViewBuffer

    init() {
        let textView = RangeConfigurableTextView(usingTextLayoutManager: false)
        textView.strategy = HashtagRangeStrategy(wrapping: WordRangeStrategy())
        self.buffer = NSTextViewBuffer(textView: textView)
    }

    @Test(
      "without leading hashes selects word",
      arguments: [
        ("foo mcˇ bar", "foo «mc» bar"),
        ("你   好ˇ",     "你   «好»"),
      ])
    func withoutLeadingHashes(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }

    @Test(
      "with one leading hash selects word up to hash",
      arguments: [
        ("foo #mcˇ bar", "foo #«mc» bar"),
        ("#fooˇ mc bar", "#«foo» mc bar"),
        ("你   #好ˇ",     "你   #«好»"),
        ("#你ˇ   好",     "#«你»   好"),
      ])
    func withOneLeadingHash(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }

    @Test(
      "with three leading hashes selects word and two hashes",
      arguments: [
        ("foo ###mcˇ bar", "foo #«##mc» bar"),
        ("###fooˇ mc bar", "#«##foo» mc bar"),
        ("你   ###好ˇ",     "你   #«##好»"),
        ("###你ˇ   好",     "#«##你»   好"),
      ])
    func withLeadingHashes(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }
}
