//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Testing
import TextKitAutoCompletion
import TextBuffer
import TextBufferTesting
import AppKit

@MainActor
@Suite
struct WikilinkRangeStrategyTests: BufferTestsBase {
    let buffer: NSTextViewBuffer

    init() {
        let textView = RangeConfigurableTextView(usingTextLayoutManager: false)
        textView.strategy = WikilinkRangeStrategy(
            wrapping: WordRangeStrategy(),
            includingBracketsInMatchedRange: true
        )
        self.buffer = NSTextViewBuffer(textView: textView)
    }

    @Test(
        "without leading brackets selects word",
        arguments: [
            ("foo mcˇ bar", "foo «mc» bar"),
            ("你   好ˇ",     "你   «好»"),
        ])
    func withoutLeadingBrackets(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }

    @Test(
        "with one leading bracket selects word",
        arguments: [
            ("foo [mcˇ bar", "foo [«mc» bar"),
            ("[fooˇ mc bar", "[«foo» mc bar"),
            ("你   [好ˇ",     "你   [«好»"),
            ("[你ˇ   好",     "[«你»   好"),
        ])
    func with1LeadingBracket(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }

    @Test(
        "with two leading brackets selects word and two brackets",
        arguments: [
            ("foo [[mcˇ bar", "foo «[[mc» bar"),
            ("[[fooˇ mc bar", "«[[foo» mc bar"),
            ("你   [[好ˇ",     "你   «[[好»"),
            ("[[你ˇ   好",     "«[[你»   好"),
        ])
    func with2LeadingBrackets(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }

    @Test(
        "with three leading brackets selects word and two brackets",
        arguments: [
            ("foo [[[mcˇ bar", "foo [«[[mc» bar"),
            ("[[[fooˇ mc bar", "[«[[foo» mc bar"),
            ("你   [[[好ˇ",     "你   [«[[好»"),
            ("[[[你ˇ   好",     "[«[[你»   好"),
        ])
    func with3LeadingBrackets(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }

    @Test(
        "with brackets mixed with letters",
        arguments: [
            ("[foo[barˇ",   "[foo[«bar»"),
            ("[[foo[[barˇ", "[[foo«[[bar»"),
            ("[你[好ˇ",      "[你[«好»"),
            ("[[你[[好ˇ",    "[[你«[[好»"),
        ])
    func bracketsMixedWithLetters(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }
}
