//
//  HighScore.h
//  Socks
//
//  Created by Dan Akselrod on 8/4/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScoreManager : NSObject
{
    int lastScore;
    int highestScore;
    //NSString *currentPlayer; TODO: multiplayer
}
+ (id) sharedScoreManager;

@property (nonatomic, readonly) int highestScore;
@property (nonatomic, readonly) int lastScore;

//@property (nonatomic, readonly) NSString *currentPlayer;
//@property (nonatomic, readonly) NSArray *registeredPlayers;
//- (void) loadPlayer: (NSString*)newPlayer;

- (void) reportScore:(int)score;

@end
