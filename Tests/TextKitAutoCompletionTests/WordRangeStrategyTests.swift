//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Testing
import TextKitAutoCompletion
import TextBuffer
import TextBufferTesting
import AppKit

/// 'ZERO WIDTH JOINER'
private let ZWJ = "\u{200D}"

@Suite
struct WordRangeStrategyTests: BufferTestsBase {
    @MainActor let buffer: NSTextViewBuffer

    init() {
        let textView = RangeConfigurableTextView(usingTextLayoutManager: false)
        textView.strategy = WordRangeStrategy()
        self.buffer = NSTextViewBuffer(textView: textView)
    }

    @Test(
      "expands to full word before point",
      arguments: [
        ("Helloˇ, World!", "«Hello», World!"),
        ("Hello, Worldˇ!", "Hello, «World»!"),
        ("你好ˇ",           "«你好»"),
        ("你   好ˇ",        "你   «好»"),
      ]
    )
    func expandsToWordBeforePoint(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }

    @Test(
      "expands to both letters and numbers before point",
      arguments: [
        ("davie504ˇ",      "«davie504»"),
      ]
    )
    func expandsToLettersAndNumbersBeforePoint(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }

    @Test(
      "expands to word part before point, ignoring remainder",
      arguments: [
        ("Heˇllo, World!", "«He»llo, World!"),
        ("Hello, Worˇld!", "Hello, «Wor»ld!"),
      ])
    func expandsToWordPartBeforePoint(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }

    @Test(
      "does not skip over punctuation marks",
      arguments: [
        ("Hello,ˇ World!",  "Hello,ˇ World!"),
        ("Hello, World!ˇ",  "Hello, World!ˇ"),
        ("你、ˇ好",          "你、ˇ好"),  // IDEOGRAPHIC COMMA
        ("你。ˇ好",          "你。ˇ好"),  // IDEOGRAPHIC PERIOD
        ("你､ˇ好",          "你､ˇ好"),  // HALFWIDTH IDEOGRAPHIC COMMA
        ("你｡ˇ好",          "你｡ˇ好"),  // HALFWIDTH IDEOGRAPHIC PERIOD
        ("(Hello)ˇ World!", "(Hello)ˇ World!"),
        ("你   〔好〕ˇ",        "你   〔好〕ˇ"),
        ("你   《好》ˇ",        "你   《好》ˇ"),
      ])
    func ignorePunctuationMarks(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }

    @Test(
      "expands to composite word with hyphen",
      arguments: [
        ("The common-wealthˇ is poor", "The «common-wealth» is poor"),
        ("The common-weaˇlth is poor", "The «common-wea»lth is poor"),
        ("The commonˇ-wealth is poor", "The «common»-wealth is poor"),
        ("The commˇon-wealth is poor", "The «comm»on-wealth is poor"),
        ("Un\(ZWJ)commonˇ",            "«Un\(ZWJ)common»"),
      ])
    func expandsToWordWithHyphen(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }

    @Test(
      "does not expand to only composition characters",
      arguments: [
        ("but --ˇ also", "but --ˇ also"),
        ("but __ˇ also", "but __ˇ also"),
      ])
    func ignoreCompositionOnly(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }

    @Test(
      "excludes hash signs by default",
      arguments: [
          ("#fooˇ",    "#«foo»"),
          ("bar#fooˇ", "bar#«foo»"),
          ("#好ˇ",      "#«好»"),
          ("你#好ˇ",    "你#«好»"),
      ])
    func ignoreHashes(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }

    @Test(
      "excludes brackets by default",
      arguments: [
        ("[fooˇ",     "[«foo»"),
        ("[好ˇ",       "[«好»"),
        ("[[fooˇ",    "[[«foo»"),
        ("[[好ˇ",      "[[«好»"),
        ("bar[fooˇ",  "bar[«foo»"),
        ("你[好ˇ",     "你[«好»"),
        ("bar[[fooˇ", "bar[[«foo»"),
        ("你[[好ˇ",    "你[[«好»"),
      ])
    func ignoreBrackets(input: String, expected: String) throws {
        try expect(rangeOf: input, toBe: expected)
    }
}
