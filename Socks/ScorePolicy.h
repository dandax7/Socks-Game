//
//  ScorePolicy.h
//  Socks
//
//  Created by Dan Akselrod on 4/29/15.
//  Copyright (c) 2015 dantap. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ScorePolicy : NSObject
{
    CGFloat baseAnimationSpeed;
    int     multAnimationSpeed;
    enum {
        INIT_CYCLE,
        RINSE_CYCLE, WASH_CYCLE, SPIN_CYCLE
    } cycleState;
}

@property (nonatomic, readonly) int shapesCount;
@property (nonatomic, readonly) CGFloat animationSpeed;
@property (nonatomic, readonly) NSTimeInterval cycleTime;
@property (nonatomic, readonly) NSString* cycleName;

@property (nonatomic, readonly) int lives;
@property (nonatomic, readonly) int matchedSockPoints;
@property (nonatomic, readonly) int unmatchedSockPoints;
@property (nonatomic) int score;
@property (nonatomic) BOOL isWin;

- (void) nextCycle;
- (BOOL) lostALife;

// instantiation
+ (ScorePolicy*) firstScorePolicy;

@end
