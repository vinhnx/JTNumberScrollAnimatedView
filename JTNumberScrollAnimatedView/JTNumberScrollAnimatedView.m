//
//  JTNumberScrollAnimatedView.m
//  JTNumberScrollAnimatedView
//
//  Created by Jonathan Tribouharet
//

#import "JTNumberScrollAnimatedView.h"

@interface JTNumberScrollAnimatedView(){
    NSMutableArray *numbersText;
    NSMutableArray *scrollLayers;
    NSMutableArray *scrollLabels;
}
@end

@implementation JTNumberScrollAnimatedView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(!self){
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(!self){
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (void)commonInit
{
    self.duration = 1.5;
    self.durationOffset = .2;
    self.density = 5;
    self.minLength = 0;
    self.isAscending = NO;
    
    self.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    self.textColor = [UIColor blackColor];
    
    numbersText = [NSMutableArray new];
    scrollLayers = [NSMutableArray new];
    scrollLabels = [NSMutableArray new];
}

- (void)setTextColor:(UIColor *)textColor
{
    if (_textColor != textColor) {
        _textColor = textColor;
    }
    
    [scrollLabels enumerateObjectsUsingBlock:^(UILabel  *_Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
        label.textColor = textColor;
    }];
}

- (void)setFont:(UIFont *)font
{
    if (_font != font) {
        _font = font;
    }
    
    [scrollLabels enumerateObjectsUsingBlock:^(UILabel  *_Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
        label.font = font;
    }];
}

- (void)setValue:(NSNumber *)value
{
    self->_value = value;
    
    [self prepareAnimations];
}

- (void)startAnimation
{
    [self prepareAnimations];
    [self createAnimations];
}

- (void)stopAnimation
{
    for(CALayer *layer in scrollLayers){
        [layer removeAnimationForKey:@"JTNumberScrollAnimatedView"];
    }
}

- (void)prepareAnimations
{
    for(CALayer *layer in scrollLayers){
        [layer removeFromSuperlayer];
    }
    
    [numbersText removeAllObjects];
    [scrollLayers removeAllObjects];
    [scrollLabels removeAllObjects];
    
    [self createNumbersText];
    [self createScrollLayers];
}

- (void)createNumbersText
{
    NSString *textValue = [self.value stringValue];
    
    for(NSInteger i = 0; i < (NSInteger)self.minLength - (NSInteger)[textValue length]; ++i){
        [numbersText addObject:@"0"];
    }
    
    for(NSUInteger i = 0; i < [textValue length]; ++i){
        [numbersText addObject:[textValue substringWithRange:NSMakeRange(i, 1)]];
    }
    
    self.text = [numbersText componentsJoinedByString:@""];
}

- (void)createScrollLayers
{
    CGFloat width = roundf(CGRectGetWidth(self.frame) / numbersText.count);
    CGFloat height = CGRectGetHeight(self.frame);
    
    for(NSUInteger i = 0; i < numbersText.count; ++i){
        CAScrollLayer *layer = [CAScrollLayer layer];
        layer.frame = CGRectMake(roundf(i * width), 0, width, height);
        [scrollLayers addObject:layer];
        [self.layer addSublayer:layer];
    }
    
    for(NSUInteger i = 0; i < numbersText.count; ++i){
        CAScrollLayer *layer = scrollLayers[i];
        NSString *numberText = numbersText[i];
        [self createContentForLayer:layer withNumberText:numberText];
    }
}

- (void)createContentForLayer:(CAScrollLayer *)scrollLayer withNumberText:(NSString *)numberText
{
    NSInteger number = [numberText integerValue];
    NSMutableArray *textForScroll = [NSMutableArray new];
    
    for(NSUInteger i = 0; i < self.density + 1; ++i){
        [textForScroll addObject:[NSString stringWithFormat:@"%lu", (number + i) % 10]];
    }
    
    [textForScroll addObject:numberText];
    
    if(!self.isAscending){
        textForScroll = [[[textForScroll reverseObjectEnumerator] allObjects] mutableCopy];
    }
    
    CGFloat height = 0;
    for(NSString *text in textForScroll){
        UILabel * textLabel = [self createLabel:text];
        textLabel.frame = CGRectMake(0, height, CGRectGetWidth(scrollLayer.frame), CGRectGetHeight(scrollLayer.frame));
        [scrollLayer addSublayer:textLabel.layer];
        [scrollLabels addObject:textLabel];
        height = CGRectGetMaxY(textLabel.frame);
    }
}

- (UILabel *)createLabel:(NSString *)text
{
    UILabel *view = [UILabel new];
    
    view.textColor = self.textColor;
    view.font = self.font;
    view.textAlignment = NSTextAlignmentCenter;
    
    view.text = text;
    return view;
}

- (void)createAnimations
{
    if (!self.shouldStartAnimation) {
        self.shouldStartAnimation = YES;
    }
    
    [scrollLayers enumerateObjectsUsingBlock:^(CALayer *scrollLayer, NSUInteger idx, BOOL * _Nonnull stop) {
        [CATransaction begin];
        scrollLayer.hidden = YES;
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.y"];
        animation.duration = 1;
        animation.beginTime = CACurrentMediaTime() + idx * self.duration / self.minLength;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeBoth;
        animation.fromValue = @(-1);
        animation.toValue = 0;
        [CATransaction setCompletionBlock:^{
            scrollLayer.hidden = NO;
        }];
        [scrollLayer addAnimation:animation forKey:@"JTNumberScrollAnimatedView"];
        [CATransaction commit];
    }];
}

@end
