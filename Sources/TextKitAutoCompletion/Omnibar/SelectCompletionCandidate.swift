//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

struct SelectCompletionCandidate {
    let handler: (_ candidate: CompletionCandidate) -> Void

    init(handler: @escaping (_: CompletionCandidate) -> Void) {
        self.handler = handler
    }

    func select(candidate: CompletionCandidate) {
        handler(candidate)
    }

    @inlinable @inline(__always)
    func callAsFunction(candidate: CompletionCandidate) {
        select(candidate: candidate)
    }
}
