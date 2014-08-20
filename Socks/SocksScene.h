//
//  MyScene.h
//  Socks
//

//  Copyright (c) 2014 dantap. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@protocol GameDelegate;
@class SockSprite;
@class Score;

@interface SocksScene : SKScene <SKPhysicsContactDelegate>
{
    CFTimeInterval last_create;
    CFTimeInterval last_create_attempt;

    BOOL system_paused;
    BOOL button_paused;
    BOOL game_over;
    
    int pause_steps_to_take;   // steps left to take pausing
    int unpause_steps_to_take; // steps left to take unpausing
    CGFloat water_height;
    
    CFTimeInterval last_frame_time;
    CFTimeInterval running_time; // time we've been running unpaused
}

@property(nonatomic, retain) SKLabelNode *pause_lbl;
@property(nonatomic, retain) id<GameDelegate> gameDelegate;

-(void)createWater: (CGSize) size;
-(void)flowBackground: (CGSize) size;
-(void)flowSock:(SockSprite*)sock;
-(void)physicsOnSock:(SockSprite*)sock;
-(void)pauseUnpause:(id)button;
-(void)gameOver;
-(BOOL)isGameOver;

@end
