//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

struct SelectWord {
    let handler: (_ word: Word) -> Void

    init(handler: @escaping (_: Word) -> Void) {
        self.handler = handler
    }

    func select(word: Word) {
        handler(word)
    }

    @inlinable @inline(__always)
    func callAsFunction(word: Word) {
        select(word: word)
    }
}
