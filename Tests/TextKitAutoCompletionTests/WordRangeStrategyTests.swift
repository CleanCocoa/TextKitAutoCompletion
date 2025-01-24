//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Testing
@testable import TextKitAutoCompletion
import TextBuffer
import TextBufferTesting
import AppKit

@MainActor
@Suite
struct WordRangeStrategyTests: BufferTestsBase {
    /// 'ZERO WIDTH JOINER'
    let ZWJ = "\u{200D}"

    let buffer: NSTextViewBuffer

    init() {
        let textView = RangeConfigurableTextView(usingTextLayoutManager: false)
        textView.strategy = WordRangeStrategy()
        self.buffer = NSTextViewBuffer(textView: textView)
    }

    @Test("expands to full word before point")
    func expandsToWordBeforePoint() throws {
        try expect(rangeOf: "Helloˇ, World!", toBe: "«Hello», World!")
        try expect(rangeOf: "Hello, Worldˇ!", toBe: "Hello, «World»!")
    }

    @Test("expands to word part before point, ignoring remainder")
    func expandsToWordPartBeforePoint() throws {
        try expect(rangeOf: "Heˇllo, World!", toBe: "«He»llo, World!")
        try expect(rangeOf: "Hello, Worˇld!", toBe: "Hello, «Wor»ld!")
    }

    @Test("does not skip over puctuation marks")
    func ignorePunctuationMarks() throws {
        try expect(rangeOf: "Hello,ˇ World!",  toBe: "Hello,ˇ World!")
        try expect(rangeOf: "Hello, World!ˇ",  toBe: "Hello, World!ˇ")
        try expect(rangeOf: "(Hello)ˇ World!", toBe:"(Hello)ˇ World!")
    }

    @Test("expands to composite word with hyphen")
    func expandsToWordWithHyphen() throws {
        try expect(rangeOf: "The common-wealthˇ is poor", toBe: "The «common-wealth» is poor")
        try expect(rangeOf: "The common-weaˇlth is poor", toBe: "The «common-wea»lth is poor")
        try expect(rangeOf: "The commonˇ-wealth is poor", toBe: "The «common»-wealth is poor")
        try expect(rangeOf: "The commˇon-wealth is poor", toBe: "The «comm»on-wealth is poor")
        try expect(rangeOf: "Un\(ZWJ)commonˇ",            toBe: "«Un\(ZWJ)common»")
    }

    @Test("does not expand to only composition characters")
    func ignoreCompositionOnly() throws {
        try expect(rangeOf: "but --ˇ also", toBe: "but --ˇ also")
        try expect(rangeOf: "but __ˇ also", toBe: "but __ˇ also")
    }
}
