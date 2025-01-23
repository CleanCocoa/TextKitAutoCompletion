//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Testing
@testable import TextKitAutoCompletion
import DeclarativeTextKit
import DeclarativeTextKitTesting
import AppKit

@MainActor
@Suite("rangeForUserCompletion")
struct RangeConfigurableTextViewTests {

    /// 'ZERO WIDTH JOINER'
    let ZWJ = "‍"

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

    func selectingRangeForUserCompletion(
      buffer value: String,
      `do` block: (_ buffer: NSTextViewBuffer) throws -> Void
    ) throws {
        try with(buffer: value) { buffer in
            buffer.select(buffer.textView.rangeForUserCompletion)
            try block(buffer)
        }
    }

    @Test("expands to full word before point")
    func expandsToWordBeforePoint() throws {
        try selectingRangeForUserCompletion(buffer: "Helloˇ, World!") { #expect($0 == "«Hello», World!") }
        try selectingRangeForUserCompletion(buffer: "Hello, Worldˇ!") { #expect($0 == "Hello, «World»!") }
    }

    @Test("expands to word part before point, ignoring remainder")
    func expandsToWordPartBeforePoint() throws {
        try selectingRangeForUserCompletion(buffer: "Heˇllo, World!") { #expect($0 == "«He»llo, World!") }
        try selectingRangeForUserCompletion(buffer: "Hello, Worˇld!") { #expect($0 == "Hello, «Wor»ld!") }
    }

    @Test("does not skip over puctuation marks")
    func ignorePunctuationMarks() throws {
        try selectingRangeForUserCompletion(buffer: "Hello,ˇ World!") { #expect($0 == "Hello,ˇ World!") }
        try selectingRangeForUserCompletion(buffer: "Hello, World!ˇ") { #expect($0 == "Hello, World!ˇ") }
        try selectingRangeForUserCompletion(buffer: "(Hello)ˇ World!") { #expect($0 == "(Hello)ˇ World!") }
    }

    @Test("expands to composite word with hyphen")
    func expandsToWordWithHyphen() throws {
        try selectingRangeForUserCompletion(buffer: "The common-wealthˇ is poor") { #expect($0 == "The «common-wealth» is poor") }
        try selectingRangeForUserCompletion(buffer: "The common-weaˇlth is poor") { #expect($0 == "The «common-wea»lth is poor") }
        try selectingRangeForUserCompletion(buffer: "The commonˇ-wealth is poor") { #expect($0 == "The «common»-wealth is poor") }
        try selectingRangeForUserCompletion(buffer: "The commˇon-wealth is poor") { #expect($0 == "The «comm»on-wealth is poor") }

        try selectingRangeForUserCompletion(buffer: "Un\(ZWJ)commonˇ") { #expect($0 == "«Un\(ZWJ)common»") }
    }

    @Test("does not expand to only composition characters")
    func ignoreCompositionOnly() throws {
        try selectingRangeForUserCompletion(buffer: "but --ˇ also") { #expect($0 == "but --ˇ also") }
        try selectingRangeForUserCompletion(buffer: "but __ˇ also") { #expect($0 == "but __ˇ also") }
    }
}
