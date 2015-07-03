//
//  ScorePolicy.m
//  Socks
//
//  Created by Dan Akselrod on 4/29/15.
//  Copyright (c) 2015 dantap. All rights reserved.
//

#import "ScorePolicy.h"

@implementation ScorePolicy


- (id) init
{
    if (self = [super init])
    {
        _lives = 5;
        _score = 0;
        _shapesCount = 1;
        _isWin = NO;
        baseAnimationSpeed = 0;
        multAnimationSpeed = 0;
        cycleState = INIT_CYCLE;
    }
    return self;
}

- (int) unmatchedSockPoints
{
    return _matchedSockPoints/2;
}

- (CGFloat) animationSpeed
{
    return baseAnimationSpeed + .2 * multAnimationSpeed;
}

- (BOOL)lostALife
{
    _lives--;
    return _lives <= 0;
}

+ (ScorePolicy*) firstScorePolicy
{
    return [[ScorePolicy alloc] init];
}

- (void) nextCycle
{
    switch (cycleState)
    {
        case INIT_CYCLE:
            cycleState = RINSE_CYCLE;
            _matchedSockPoints = 10 + 5 * _shapesCount;
            _cycleTime = 30;
            baseAnimationSpeed = 1;
            _cycleName = [NSString stringWithFormat: @"Rinse %d", _shapesCount];
            break;

        case RINSE_CYCLE:
            cycleState = WASH_CYCLE;
            _matchedSockPoints = 20 + 5 * _shapesCount;
            baseAnimationSpeed = 1.5;
            _cycleName = [NSString stringWithFormat: @"Wash %d", _shapesCount];;
            break;
            
        case WASH_CYCLE:
            cycleState = SPIN_CYCLE;
            _matchedSockPoints = 30 + 5 * _shapesCount;
            baseAnimationSpeed = 1.8;
            _cycleName = [NSString stringWithFormat: @"Spin %d", _shapesCount];;
            break;
            
        case SPIN_CYCLE:
            cycleState = RINSE_CYCLE; // again
            _shapesCount++;
            _matchedSockPoints = 10 + 5 * _shapesCount;
            baseAnimationSpeed = 1;
            multAnimationSpeed ++;
            _cycleName = [NSString stringWithFormat: @"Rinse %d", _shapesCount];;
            break;
   }
}

@end
