//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Testing
import TextBuffer
import TextBufferTesting
import AppKit

/// Shared test helpers operating on ``buffer`.
@MainActor  // Main actor isolation helps with NSTextViewBuffer tests.
protocol BufferTestsBase {
    associatedtype Buffer: TextBuffer.Buffer
    var buffer: Buffer { get }

    func selectingRangeForUserCompletion(
      buffer value: String,
      `do` block: (_ buffer: NSTextViewBuffer) throws -> Void
    ) throws

    func expect(
      rangeOf bufferContent: String,
      toBe expectation: String,
      sourceLocation: SourceLocation
    ) throws
}

extension BufferTestsBase {
    func expect(
      rangeOf bufferContent: String,
      toBe expectation: String,
      sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        try selectingRangeForUserCompletion(buffer: bufferContent) { actual in
            #expect(actual == expectation, sourceLocation: sourceLocation)
        }
    }
}

extension BufferTestsBase where Buffer: TextBuffer.NSTextViewBuffer {
    func selectingRangeForUserCompletion(
      buffer value: String,
      `do` block: (_ buffer: NSTextViewBuffer) throws -> Void
    ) throws {
        try change(buffer: buffer, to: value)
        buffer.select(buffer.textView.rangeForUserCompletion)
        try block(buffer)
    }
}
