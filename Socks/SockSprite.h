//
//  SockSprite.h
//  Socks
//
//  Created by Dan Akselrod on 3/30/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef void(^float_callback)(float);

typedef struct
{
    int shape;
    int pattern;
} SockId;

SockId MakeNullSockId();
BOOL isNullSockId(SockId sid);

@interface SockSprite : SKSpriteNode
{
    CGFloat fall_speed;
}

@property (nonatomic, weak) UITouch *moving_touch;
@property (nonatomic) SockId sock_id;
@property (nonatomic) CGPoint pause_saved_position;
@property (nonatomic) CGPoint pause_speed;
@property (nonatomic) BOOL out_of_play;
@property (nonatomic, readonly) BOOL is_flowing;

+ (void)loadTextures: (float_callback) progress_cb;
+ (SockSprite*) sockWithSockId:(SockId)sid;
+ (SockId) pickRandomId: (int)maxShapes;
+ (int) maxShapes;

- (BOOL)sameTypeAs: (SockSprite*)other;
- (void)startFlowWith: (CGFloat)speed turn:(CGFloat)degree;
- (void)stopFlow;
- (void)moveAwayByX:(CGFloat)x
                  y:(CGFloat)y
               with:(SockSprite*)other
           duration:(NSTimeInterval)duration;
- (CGPoint)futurePoint:(NSTimeInterval)future;
@end

