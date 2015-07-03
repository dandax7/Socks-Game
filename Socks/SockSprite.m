//
//  SockSprite.m
//  Socks
//
//  Created by Dan Akselrod on 3/30/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import "SockSprite.h"
#import "SockMatrix.h"
#import <math.h>

static SockMatrix* g_sockTextures;

SockId MakeNullSockId()
{
    SockId ret = { -1, -1 };
    return ret;
}

BOOL isNullSockId(SockId sid)
{
    return (sid.shape == -1 || sid.pattern == -1);
}

@implementation SockSprite
@synthesize moving_touch;
@synthesize sock_id;
@synthesize pause_saved_position;
@synthesize pause_speed;
@synthesize out_of_play;

+(void)loadTextures:(float_callback) progress_cb
{
    int pattern_end, shapes_end;
    
    for (pattern_end = 1;;pattern_end++)
    {
        NSString *pattern_name = [NSString stringWithFormat: @"pattern%d.png", pattern_end];
        NSString *full_path = [[NSBundle mainBundle] pathForResource: pattern_name ofType: nil];
        if (![[NSFileManager defaultManager] fileExistsAtPath: full_path])
            break;
    }
    
    for(shapes_end = 1;;shapes_end++)
    {
        NSString *sock_name = [NSString stringWithFormat: @"sock%d.png", shapes_end];
        NSString *full_path = [[NSBundle mainBundle] pathForResource: sock_name ofType: nil];
        if (![[NSFileManager defaultManager] fileExistsAtPath: full_path])
            break;
    }

    // we have [1 .. pattern_end) patterns
    //         [1 .. shapes_end) shapes
    
    g_sockTextures = [SockMatrix matrixWithShapes: shapes_end - 1
                                         Patterns: pattern_end - 1];
    
    NSMutableArray *patterns = [[NSMutableArray alloc] initWithCapacity: (pattern_end - 1)];
    
    for (int pattern = 1; pattern < pattern_end;pattern++)
    {
        NSString *pattern_name = [NSString stringWithFormat: @"pattern%d.png", pattern];
        CIImage *pattern = [CIImage imageWithCGImage:[[UIImage imageNamed: pattern_name] CGImage]];
        [patterns addObject: pattern];
    }
    
    const float total = (shapes_end - 1) * (pattern_end - 1);
    float done =0;
    
    for(int shape_num = 1; shape_num < shapes_end;shape_num++)
    {
        NSString *shape_name = [NSString stringWithFormat: @"sock%d.png", shape_num];
        int sock_pat = 1;
        for (CIImage* pattern in patterns)
        {
            CIContext *context = [CIContext contextWithOptions:nil];
            CIImage *inputImage = [CIImage imageWithCGImage:[[UIImage imageNamed: shape_name] CGImage]];
            
            CIFilter *patternFilter = [CIFilter filterWithName:@"CIMinimumCompositing"];
            [patternFilter setValue:inputImage forKey: @"inputImage"];
            [patternFilter setValue:pattern forKey: @"inputBackgroundImage"];
            CIImage *result = [patternFilter outputImage];
            CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
            SKTexture *sock_txture = [SKTexture textureWithCGImage: cgImage];
            
            [g_sockTextures insertSock:sock_txture
                                 Shape:shape_num - 1
                               Pattern:sock_pat - 1]; // -1 since we start at 1
            CGImageRelease(cgImage);
            sock_pat ++;

            progress_cb(++done/ total);
        }
    }
}

+ (SockSprite*) sockWithSockId:(SockId)sid
{
    SockSprite *new_sprite = [SockSprite
                              spriteNodeWithTexture:
                              [g_sockTextures getSockShape:sid.shape
                                                   Pattern:sid.pattern]
                              size: CGSizeMake(40,60)];
    new_sprite.sock_id = sid;
    new_sprite.out_of_play = NO;
    return new_sprite;
}

+ (SockId)pickRandomId:(int)maxShapes
{
    SockId ret;
    ret.shape = maxShapes > 1 ? arc4random_uniform(maxShapes) : 0;
    ret.pattern = arc4random_uniform(g_sockTextures.patterns);
    return ret;
}

+ (int) maxShapes
{
    return [g_sockTextures shapes];
}

- (BOOL)sameTypeAs: (SockSprite*)other
{
    SockId self_id = self.sock_id;
    SockId other_id = other.sock_id;
    
    return (self_id.pattern == other_id.pattern &&
            self_id.shape == other_id.shape);
}

- (void)startFlowWith: (CGFloat)new_speed turn:(CGFloat)degree
{
    fall_speed = new_speed;
    
    SKAction *move = [SKAction moveBy: CGVectorMake(0, -new_speed) duration:1];
    SKAction *spin = [SKAction rotateByAngle: degree duration:1];
    SKAction *move_spin = [SKAction repeatActionForever: [SKAction group:@[move, spin]]];
    
    [self runAction: move_spin];
}

- (void)stopFlow
{
    fall_speed = 0;
    [self removeAllActions];
}

- (void)moveAwayByX:(CGFloat)x
                  y:(CGFloat)y
               with:(SockSprite*)other
           duration:(NSTimeInterval)duration
{
    // out of play, no physicsContact, no other annimations
    [self removeAllActions];
    [other removeAllActions];

    self.out_of_play = YES;
    other.out_of_play = YES;
    
    self.physicsBody.categoryBitMask = 0;
    self.physicsBody.contactTestBitMask = 0;
    other.physicsBody.categoryBitMask = 0;
    other.physicsBody.contactTestBitMask = 0;

    
    // new position
    CGPoint c1 = self.position;
    CGPoint c2 = other.position;
    
    // bring them closer
    CGFloat c1xd = (c2.x - c1.x) * .4;
    CGFloat c1yd = (c2.y - c1.y) * .4;
    CGFloat c2xd = (c1.x - c2.x) * .4;
    CGFloat c2yd = (c1.y - c2.y) * .4;
    
    SKAction *move_close1 = [SKAction moveByX: c1xd y:c1yd duration: duration*.33];
    SKAction *move_close2 = [SKAction moveByX: c2xd y:c2yd duration: duration*.33];
    SKAction *straight = [SKAction rotateToAngle:0 duration:duration * .33];
    
    SKAction *straight_n_tight1 = [SKAction group: @[move_close1, straight]];
    SKAction *straight_n_tight2 = [SKAction group: @[move_close2, straight]];

    SKAction *move_away = [SKAction moveByX: x y:y duration:duration * .66];
    
    SKAction *exit1 = [SKAction sequence: @[ straight_n_tight1, move_away, [SKAction removeFromParent]]];
    SKAction *exit2 = [SKAction sequence: @[ straight_n_tight2, move_away, [SKAction removeFromParent]]];

    [self runAction: exit1];
    [other runAction: exit2];
}

- (CGPoint)futurePoint:(NSTimeInterval)future
{
    CGPoint p = self.position;
    p.y -= fall_speed * future;
    
    return p;
}

-(BOOL)isIs_flowing
{
    return fall_speed != 0;
}

@end
