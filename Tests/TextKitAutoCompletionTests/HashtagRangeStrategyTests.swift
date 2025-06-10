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
        let textView = RangeConfigurableTextView(
            strategy: HashtagRangeStrategy(
                wrapping: WordRangeStrategy(),
                isMatchingFirstHash: false
            )
        )
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
        "with 2 leading hash selects word up to hash",
        arguments: [
            ("foo ##mcˇ bar", "foo #«#mc» bar"),
        ])
    func withTwoLeadingHash(input: String, expected: String) throws {
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

    @Test(
      "with hashes mixed with letters",
      arguments: [
        ("#foo#barˇ",  "#foo#«bar»"),
        ("#foo##barˇ", "#foo#«#bar»"),
        ("#你#好ˇ",     "#你#«好»"),
        ("#你##好ˇ",    "#你#«#好»"),
      ])
    func hashesMixedWithLetters(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }

    @Test(
      "include first hash in matches",
      arguments: [
        // No Hash
        ("foo mcˇ bar", "foo «mc» bar"),
        ("你   好ˇ",     "你   «好»"),
        // One leading hash
        ("foo #mcˇ bar", "foo «#mc» bar"),
        ("#fooˇ mc bar", "«#foo» mc bar"),
        ("你   #好ˇ",     "你   «#好»"),
        ("#你ˇ   好",     "«#你»   好"),
        // Multiple leading hashes
        ("foo ###mcˇ bar", "foo «###mc» bar"),
        ("###fooˇ mc bar", "«###foo» mc bar"),
        ("你   ###好ˇ",     "你   «###好»"),
        ("###你ˇ   好",     "«###你»   好"),
        // No whitespace
        ("#foo#barˇ",  "#foo«#bar»"),
        ("#foo##barˇ", "#foo«##bar»"),
        ("#你#好ˇ",     "#你«#好»"),
        ("#你##好ˇ",    "#你«##好»"),
      ])
    func includingFirstHashInMatch(input: String, expected: String) throws {
        (self.buffer.textView as! RangeConfigurableTextView).strategy = HashtagRangeStrategy(wrapping: WordRangeStrategy(), isMatchingFirstHash: true)
        try expect(rangeOf: input, toBe: expected)
    }
}
