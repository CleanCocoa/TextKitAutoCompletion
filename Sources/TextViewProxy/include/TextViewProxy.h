//
//  TextViewProxy.h
//  TextKitAutoCompletion
//
//  Created by Christian Tietze on 11.01.25.
//

@import AppKit;

NS_ASSUME_NONNULL_BEGIN

@protocol TextViewProxyDelegate
- (void)proxiedTextView:(NSTextView *)textView willInvokeSelector:(SEL)selector;
@end

/// Proxies messages passed down the responder chain to its ``textView`` and informs ``proxyInvocationCallback`` for each proxied call.
///
/// Introduced to forward main menu item validation and usage from the completion popover, which becomes key window, to the text view that runs the completion session. The callback then will be used to distinguish menu item validation (via `responds(to:)`) from execution (via one of the `perform` overloads). During execution, we want to automatically cancel the completion session.
NS_SWIFT_SENDABLE
@interface TextViewProxy : NSProxy
@property (strong, nonnull) NSTextView *textView;
@property (weak, nullable) id<TextViewProxyDelegate> delegate;

- (id)initWithTextView:(NSTextView *)textView;

- (void)insertText:(id)insertString;
- (void)doCommandBySelector:(SEL)selector;

@end

NS_ASSUME_NONNULL_END
