# TextKitAutoCompletion

Extends TextKit's default auto-completion to support live typing suggestions.

TextKit's auto-completion can be invoked in any `NSTextView` via <kbd>F5</kbd> or <kbd>⌥</kbd>+<kbd>ESC</kbd>. It shows dictionary suggestions for the relevant word at point; but you cannot type-to-complete. Typing cancels the completion UI, so you need to hit the invocation key again after you finished typing.

This package fixes that.

## Installation

### Xcode

Paste this in Xcode's URL field:  `https://github.com/CleanCocoa/TextKitAutoCompletion`

### SwiftPM

```swift
dependencies: [
    .package(url: "https://github.com/CleanCocoa/TextKitAutoCompletion", branch: "main")
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            "TextKitAutoCompletion",
        ]
    ),
```
