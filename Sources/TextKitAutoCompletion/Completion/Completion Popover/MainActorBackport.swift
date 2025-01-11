//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

@available(macOS, deprecated: 10.15, message: "Use MainActor.assumeIsolated")
enum MainActorBackport {
    @_unavailableFromAsync
    static func assumeIsolated<T>(_ body: @MainActor @Sendable () throws -> T) rethrows -> T
    where T: Sendable {
#if swift(>=5.9)
        if #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) {
            return try MainActor.assumeIsolated(body)
        }
#endif
        dispatchPrecondition(condition: .onQueue(.main))
        return try withoutActuallyEscaping(body) { fn in
            try unsafeBitCast(fn, to: (() throws -> T).self)()
        }
    }
}
