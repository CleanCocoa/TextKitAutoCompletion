//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

/// Strategy to get to the range for user completion in a text view.
///
/// ## Implementation Notes
/// In ``rangeForUserCompletion(textView:)``, you should not rely on `textView.rangeForUserCompletion` and modify it, because that's very likely the caller of this function and would produce a cycle.
public protocol RangeForUserCompletionStrategy<LookupFailure> {
    associatedtype LookupFailure

    @MainActor
    func rangeForUserCompletion(textView: NSTextView) -> FailableRangeLookup<LookupFailure>
}

/// Strategy to get to the range for user completion in a text view that guarantees to return a range.
///
/// ## Implementation Notes
/// In ``rangeForUserCompletion(textView:)``, you should not rely on `textView.rangeForUserCompletion` and modify it, because that's very likely the caller of this function and would produce a cycle.
public protocol NonFailingRangeForUserCompletionStrategy: RangeForUserCompletionStrategy
where LookupFailure == Never {
    @MainActor
    func rangeForUserCompletion(textView: NSTextView) -> NSRange
}

extension NonFailingRangeForUserCompletionStrategy {
    @MainActor
    public func rangeForUserCompletion(textView: NSTextView) -> NSRange {
        switch self.rangeForUserCompletion(textView: textView) as JustRange {  // Disambiguage function call
        case .range(let range):
            return range
        }
    }
}
