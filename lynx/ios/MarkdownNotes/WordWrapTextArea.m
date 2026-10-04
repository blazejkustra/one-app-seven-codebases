#import "WordWrapTextArea.h"

@implementation WordWrapTextArea

- (instancetype)init {
  if (self = [super init]) {
    [self applyWordWrapping];
  }
  return self;
}

- (void)propsDidUpdate {
  [super propsDidUpdate];
  [self applyWordWrapping];
}

- (void)applyWordWrapping {
  self.inputParagraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
  self.view.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
  NSMutableDictionary *typing = [self.view.typingAttributes mutableCopy] ?: [NSMutableDictionary dictionary];
  typing[NSParagraphStyleAttributeName] = self.inputParagraphStyle;
  self.view.typingAttributes = typing;
}

@end
