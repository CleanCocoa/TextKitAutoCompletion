//
//  TextViewProxy.m
//  TextKitAutoCompletion
//
//  Created by Christian Tietze on 11.01.25.
//

#import "TextViewProxy.h"

@implementation TextViewProxy
- (id)initWithTextView:(NSTextView *)textView
{
    self.textView = textView;
    return self;
}

- (void)insertText:(id)insertString
{
    [self.textView insertText:insertString];
}

- (void)doCommandBySelector:(SEL)selector
{
    [self.delegate proxiedTextView:self.textView willInvokeSelector:selector];

    [self.textView doCommandBySelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    [self.delegate proxiedTextView:self.textView willInvokeSelector:invocation.selector];

    [invocation setTarget:self.textView];
    [invocation invoke];
    return;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [self.textView methodSignatureForSelector:sel];
}

@end
