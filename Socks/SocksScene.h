//
//  MyScene.h
//  Socks
//

//  Copyright (c) 2014 dantap. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class SockSprite;
@class Score;
@class ScorePolicy;

@interface SocksScene : SKScene <SKPhysicsContactDelegate>
{
    CFTimeInterval last_create;
    CFTimeInterval last_create_attempt;

    // score
    ScorePolicy * score_policy;
    
    NSMutableArray *sock_lives;
    
    // game state
    BOOL ad_paused;
    BOOL system_paused;
    CGFloat saved_speed;
    BOOL game_over;
    BOOL did_win;
    BOOL button_paused;        // if paused by button, even if animating pause
    int pause_steps_to_take;   // steps left to take pausing
    int unpause_steps_to_take; // steps left to take unpausing
    
    //CGFloat water_height; TODO: make id dynamic
    
    int            shapes;
    CFTimeInterval last_frame_time;
    CFTimeInterval running_time; // time we've been running unpaused
    CFTimeInterval next_cycle;
}

@property(nonatomic, retain) SKLabelNode *score_label;
@property(nonatomic, retain) SKLabelNode *score_shadow;
@property(nonatomic, retain) SKLabelNode *pause_lbl;
@property(nonatomic, readonly, getter=isInPlay) BOOL inPlay;
@property(copy) void (^doOnGameOver)(void);
@property(copy) void (^doOnWin)(void);

-(instancetype) initWithSize:(CGSize) size scorePolicy: (ScorePolicy*)spoly;
-(void)createWater: (CGSize) size;
-(void)flowBackground: (CGSize) size;
-(void)flowSock:(SockSprite*)sock;
-(void)physicsOnSock:(SockSprite*)sock;
-(void)pauseUnpause:(id)button;
-(void)systemPause;
-(void)systemUnpause;
-(void)adPause;
-(void)adUnpause;
-(void)gameOver;
-(BOOL)isGameOver;

@end
