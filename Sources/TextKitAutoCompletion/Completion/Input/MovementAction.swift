//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Action handler used by text input client to forward movement events to change the selection in search results.
@MainActor
public struct MovementAction {
    let handler: @MainActor (_ movement: Movement) -> Void

    public init(handler: @escaping @MainActor (_ movement: Movement) -> Void) {
        self.handler = handler
    }

    public func move(_ movement: Movement) {
        handler(movement)
    }

    @inlinable @inline(__always)
    public func callAsFunction(movement: Movement) {
        move(movement)
    }
}
