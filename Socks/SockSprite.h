//
//  SockSprite.h
//  Socks
//
//  Created by Dan Akselrod on 3/30/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>


@interface SockSprite : SKSpriteNode

@property (nonatomic, weak) UITouch *moving_touch;
@property (nonatomic) int sock_number;

@end

