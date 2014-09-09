//
//  HighScore.m
//  Socks
//
//  Created by Dan Akselrod on 8/4/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import "ScoreManager.h"

@implementation ScoreManager
@synthesize lastScore;
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
        [self load];
    }
    return self;
}

/*
- (NSString*)saveDirectory
{
    NSString *dir = [NSString stringWithFormat: @"%@/scores",  NSHomeDirectory()];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    BOOL isdir;
    BOOL exists =[fm fileExistsAtPath: dir isDirectory: &isdir];
    if (exists & isdir)
        return dir;
    
    if (exists && !isdir)
    {
        NSLog(@"%@ is not a directory, removing", dir);
        [fm removeItemAtPath: dir error: nil];
    }
    
    NSError *error = nil;
    BOOL ret = [fm createDirectoryAtPath:dir
             withIntermediateDirectories:YES
                              attributes:NULL
                                   error:&error];
    NSLog(@"Creating %@ -> %d (%@)", dir, ret, error);
    if (!ret)
        abort();
    
    return dir;
}*/

- (NSString*)saveFileName
{
    return [NSString stringWithFormat: @"%@/%@", NSHomeDirectory(), @"score"];
}

- (void)save
{
    NSString *saveFname = [self saveFileName];
    NSDictionary *tosave = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt: highestScore], @"highestScore",
                            [NSNumber numberWithInt:lastScore], @"lastScore", nil];

    NSLog(@"Saved %@ to %@", tosave, saveFname);
    [tosave writeToFile: saveFname atomically:YES];
}

- (void)load
{
    NSString *saveFname = [self saveFileName];
    NSDictionary *toload = [NSDictionary dictionaryWithContentsOfFile: saveFname];
    if (toload == nil)
    {
        NSLog(@"Cant load plist from %@", saveFname);
        highestScore = 0;
        lastScore = 0;
        return;
    }
    NSLog(@"Loaded plist %@ from %@", toload, saveFname);
    highestScore = [(NSNumber*)[toload valueForKey: @"highestScore"] intValue];
    lastScore =    [(NSNumber*)[toload valueForKey: @"lastScore"] intValue];
}

- (void)reportScore:(int)score
{
    NSLog(@"reporting score: %d", score);
    lastScore = score;
    if (score > highestScore)
    {
        NSLog(@"Setting to high, (old high=%d)", highestScore);
        highestScore = score;
    }
    [self save];
}

/*
- (void)loadPlayer:(NSString *)newPlayer
{
    currentPlayer = newPlayer;
    [self load];
    [[NSUserDefaults standardUserDefaults] setObject: currentPlayer forKey:@"currentPlayer"];
}

- (NSArray*)registeredPLayers
{
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: [self saveDirectory]
                                                                         error: nil];
    return files;
}*/

@end
