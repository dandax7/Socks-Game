//
//  HighScore.m
//  Socks
//
//  Created by Dan Akselrod on 8/4/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import "ScoreManager.h"

@implementation ScoreManager
@synthesize currentPlayer;
@synthesize highestScore;

+ (id) sharedScoreManager
{
    static ScoreManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    if (self = [super init])
    {
        currentPlayer = [[NSUserDefaults standardUserDefaults] stringForKey: @"currentPlayer"];
        if (currentPlayer == nil)
        {
            highestScore = 0;
            currentPlayer = @"me";
        }
        else
        {
            [self load];
        }
    }
    return self;
}

- (void)save
{
    NSString *scoreKey = [NSString stringWithFormat: @"highestScore-%@", currentPlayer];
    [[NSUserDefaults standardUserDefaults] setInteger: highestScore forKey:scoreKey];
    
    if (![NSUserDefaults standardUserDefaults].synchronize)
    {
        NSLog(@"sync failed");
    }
}

- (void)load
{
    NSString *scoreKey = [NSString stringWithFormat: @"highestScore-%@", currentPlayer];
    highestScore = [[NSUserDefaults standardUserDefaults] integerForKey: scoreKey];
}

- (void)reportScore:(int)score
{
    NSLog(@"reporting score: %d", score);
    if (score > highestScore)
    {
        NSLog(@"Setting to high, (old high=%d)", highestScore);
        highestScore = score;
        [self save];
    }
}

- (void)loadPlayer:(NSString *)newPlayer
{
    currentPlayer = newPlayer;
    [self load];
    [[NSUserDefaults standardUserDefaults] setObject: currentPlayer forKey:@"currentPlayer"];
}

- (NSArray*)registeredPLayers
{
    NSMutableArray *players = [NSMutableArray array];

    NSArray *all_keys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
    for (NSString* key in all_keys)
    {
        if (key.length < 14)
            continue;
        
        if ([[key substringToIndex:13] isEqual: @"highestScore-"])
        {
            NSString *player = [key substringFromIndex:13];
            [players addObject: player];
        }
    }
    return players;
}

@end
