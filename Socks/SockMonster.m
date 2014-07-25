//
//  SockMonster.m
//  Socks
//
//  Created by Dan Akselrod on 5/28/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import "SockMonster.h"
#import "SockSprite.h"
#import "Random.h"
@implementation SockMonster

+ (void)preload
{
    [SockMonster chompPatterns];
}

+ (NSArray*) chompPatterns
{
    static NSArray* chomp_patterns =nil;
    
    if (chomp_patterns == nil)
    {
        chomp_patterns =
        @[
          [SKTexture textureWithImageNamed: @"sock-monster-head.png"],
          [SKTexture textureWithImageNamed: @"sock-monster-lil-bent-head.png"],
          [SKTexture textureWithImageNamed: @"sock-monster-bent-head.png"],
          [SKTexture textureWithImageNamed: @"sock-monster-open.png"],
          [SKTexture textureWithImageNamed: @"sock-monster-half.png"],
          [SKTexture textureWithImageNamed: @"sock-monster-close.png"],
          ];
    }
    return chomp_patterns;
}

+ (SockMonster*) plainMonster:(CGFloat) height
{
    UIColor* transparent =[UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    
    // since our monster is not always flush to borders, we extend it just a bit
    height *= 1.1;
    
    // we want a 3:4 ratio of width:height
    //    width = 3/4 * height
    CGFloat width = .75 * height;
    CGSize size = CGSizeMake(width, height);
    SockMonster *monster = [SockMonster spriteNodeWithColor: transparent size: size];
    monster.anchorPoint = CGPointMake(.75,.80);
    monster.xScale = arc4random_boolean(.5)?-1:1;
    return monster;
}

- (void) animateSockEating: (SockSprite*)sock
                  duration: (NSTimeInterval)duration
                completion: (void (^)(void))comp_block
{
    NSArray *patterns = [SockMonster chompPatterns];
    
    NSTimeInterval to_sock = duration * .8;
    NSTimeInterval from_sock = duration - to_sock;
    
    CGPoint rend_pt = [sock futurePoint: to_sock];
    CGPoint down_pt = self.position;
    down_pt.y = -self.size.width; // below screen
    SKAction *move_to_sock = [SKAction moveTo: rend_pt duration:to_sock];
    SKAction *chomp = [SKAction animateWithTextures:patterns timePerFrame:to_sock/patterns.count];
    SKAction *eat_and_chomp = [SKAction group:@[move_to_sock, chomp]];
    SKAction *move_back_and_exit = [SKAction sequence:@[
                                                [SKAction moveTo:down_pt duration:from_sock],
                                                [SKAction removeFromParent]]];
    SKAction *spin_shrink_move_and_exit = [SKAction group: @[
                                               [SKAction rotateByAngle:M_PI duration:from_sock],
                                               [SKAction scaleXTo:0 y:0 duration:from_sock],
                                               move_back_and_exit]];

    // first we animate the rendezvous
    [self runAction:eat_and_chomp
         completion: ^{ // and animate the grabbing
             [sock stopFlow];
             [self runAction: move_back_and_exit];
             [sock runAction: spin_shrink_move_and_exit];
             comp_block();
         }];
}

@end
