//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import DeclarativeTextKit

extension NSTextViewBuffer: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        MutableStringBuffer(wrapping: self).description
    }
}

func == (lhs: Buffer, rhs: String) -> Bool {
    MutableStringBuffer(wrapping: lhs).description == rhs
}
