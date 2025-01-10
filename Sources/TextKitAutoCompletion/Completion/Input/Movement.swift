//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Movement event forwarded by the editor.
public enum Movement: Equatable {
    /// Called when the up arrow key is pressed.
    case up
    /// Called when the down arrow key is pressed.
    case down

    /// Called when the up arrow key is pressed while the Command or Alt modifier key is held.
    case top
    /// Called when the down arrow key is pressed while the Command or Alt modifier key is held.
    case bottom
}
