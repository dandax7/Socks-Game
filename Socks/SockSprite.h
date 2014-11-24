//
//  SockSprite.h
//  Socks
//
//  Created by Dan Akselrod on 3/30/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef void(^float_callback)(float);

@interface SockSprite : SKSpriteNode

@property (nonatomic, weak) UITouch *moving_touch;
@property (nonatomic) int sock_number;
@property (nonatomic) CGPoint pause_saved_position;
@property (nonatomic) CGPoint pause_speed;
@property (nonatomic) CGFloat fall_speed;
@property (nonatomic) BOOL out_of_play;

+ (int) totalSocks;
+ (void)loadTextures: (float_callback) progress_cb;
+ (SockSprite*) sockNumber: (int) num;
+ (void)revealManyShapes: (BOOL) yn;

- (void)startFlowWith: (CGFloat)speed turn:(CGFloat)degree;
- (void)stopFlow;
- (void)moveAwayByX:(CGFloat)x
                  y:(CGFloat)y
               with:(SockSprite*)other
              score:(int)score
           duration:(NSTimeInterval)duration;
- (CGPoint)futurePoint:(NSTimeInterval)future;
@end

