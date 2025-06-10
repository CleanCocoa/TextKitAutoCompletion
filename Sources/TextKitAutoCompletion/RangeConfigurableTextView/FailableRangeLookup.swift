//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

public enum FailableRangeLookup<Failure> {
    case range(NSRange)
    case failure(Failure)
}

extension FailableRangeLookup: ExpressibleByNilLiteral where Failure == Void {
    public static var none: Self { .failure(()) }

    public init(nilLiteral: ()) {
        self = .failure(())
    }
}

public typealias MaybeRange = FailableRangeLookup<Void>
public typealias JustRange = FailableRangeLookup<Never>

public func Just(_ range: NSRange) -> JustRange {
    return .range(range)
}

public func ?? <T>(lhs: FailableRangeLookup<T>, rhs: @autoclosure () -> NSRange) -> NSRange {
    switch lhs {
    case .range(let range): return range
    case .failure: return rhs()
    }
}
