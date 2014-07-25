//
//  SockMonster.h
//  Socks
//
//  Created by Dan Akselrod on 5/28/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class SockSprite;
@interface SockMonster : SKSpriteNode

+ (SockMonster*) plainMonster:(CGFloat)height;
+ (void) preload;

- (void) animateSockEating: (SockSprite*)sock
                  duration: (NSTimeInterval)duration
                completion: (void (^)(void))comp_block;


@end
