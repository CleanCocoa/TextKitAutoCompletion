//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

public struct CompletionCandidate: Equatable, Sendable {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    func startsWith(_ prefix: String) -> Bool {
        guard let matchRange = value.range(of: prefix, options: [.anchored, .caseInsensitive])
        else { return false }
        assert(matchRange.lowerBound == value.startIndex, "Anchored range search should guarantee that the match starts at startIndex, not somewhere in the middle")
        return true
    }

    func contains(_ substring: String) -> Bool {
        return value.range(of: substring, options: .caseInsensitive) != nil
    }
}
