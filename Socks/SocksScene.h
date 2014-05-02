//
//  MyScene.h
//  Socks
//

//  Copyright (c) 2014 dantap. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
@class SockSprite;

typedef void(^float_callback)(float);

@interface SocksScene : SKScene <SKPhysicsContactDelegate>
{
    int pattern_end;
    int socks_end;
    CFTimeInterval last_create;
    CFTimeInterval last_create_attempt;
    NSMutableArray *sockTextures;
    
}

-(void)loadTextures:(float_callback) progress_cb;
-(void)flowSock:(SockSprite*)sock;
-(void)physicsOnSock:(SockSprite*)sock;

@end
