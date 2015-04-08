//
//  GameDelegate.h
//  Socks
//
//  Created by Dan Akselrod on 7/11/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct _MatchedResult
{
    int score;
    CGPoint move_to;
} MatchedResult;

@protocol GameDelegate <NSObject>

- (void) sockLost;
- (MatchedResult) socksMatched;
- (int) unmatchedSock;
@end
