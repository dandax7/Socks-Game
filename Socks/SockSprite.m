//
//  SockSprite.m
//  Socks
//
//  Created by Dan Akselrod on 3/30/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import "SockSprite.h"

static NSMutableArray* g_sockTexturesManyShapes;
static NSMutableArray* g_sockTexturesOneShape;
static BOOL g_useManyShapes = NO;

NSMutableArray* currentShapesArray()
{
    return g_useManyShapes ? g_sockTexturesManyShapes : g_sockTexturesOneShape;
}

@implementation SockSprite
@synthesize moving_touch;
@synthesize sock_number;
@synthesize pause_saved_position;
@synthesize pause_speed;
@synthesize fall_speed;
@synthesize out_of_play;

+(void)loadTextures:(float_callback) progress_cb
{
    int pattern_end, socks_end;
    
    for (pattern_end = 1;;pattern_end++)
    {
        NSString *pattern_name = [NSString stringWithFormat: @"pattern%d.png", pattern_end];
        NSString *full_path = [[NSBundle mainBundle] pathForResource: pattern_name ofType: nil];
        if (![[NSFileManager defaultManager] fileExistsAtPath: full_path])
            break;
    }
    
    for(socks_end = 1;;socks_end++)
    {
        NSString *sock_name = [NSString stringWithFormat: @"sock%d.png", socks_end];
        NSString *full_path = [[NSBundle mainBundle] pathForResource: sock_name ofType: nil];
        if (![[NSFileManager defaultManager] fileExistsAtPath: full_path])
            break;
    }

    g_sockTexturesManyShapes = [[NSMutableArray alloc]initWithCapacity: (socks_end - 1) * (pattern_end - 1)];
    g_sockTexturesOneShape = [[NSMutableArray alloc]initWithCapacity: pattern_end - 1];
    
    NSMutableArray *patterns = [[NSMutableArray alloc] initWithCapacity: (pattern_end - 1)];
    
    for (int pattern = 1; pattern < pattern_end;pattern++)
    {
        NSString *pattern_name = [NSString stringWithFormat: @"pattern%d.png", pattern];
        CIImage *pattern = [CIImage imageWithCGImage:[[UIImage imageNamed: pattern_name] CGImage]];
        [patterns addObject: pattern];
    }
    
    const float total = (socks_end - 1) * (pattern_end - 1);
    float done =0;
    
    for(int socks = 1; socks < socks_end;socks++)
    {
        NSString *sock_name = [NSString stringWithFormat: @"sock%d.png", socks];
        for (CIImage* pattern in patterns)
        {
            CIContext *context = [CIContext contextWithOptions:nil];
            CIImage *inputImage = [CIImage imageWithCGImage:[[UIImage imageNamed:sock_name] CGImage]];
            
            CIFilter *patternFilter = [CIFilter filterWithName:@"CIMinimumCompositing"];
            [patternFilter setValue:inputImage forKey: @"inputImage"];
            [patternFilter setValue:pattern forKey: @"inputBackgroundImage"];
            CIImage *result = [patternFilter outputImage];
            CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
            SKTexture *sock_txture = [SKTexture textureWithCGImage: cgImage];
            [g_sockTexturesManyShapes addObject: sock_txture];
            if (socks == 5)
            {
                [g_sockTexturesOneShape addObject: sock_txture];
            }
            CGImageRelease(cgImage);
            
            progress_cb(++done/ total);
        }
    }
}


+ (SockSprite*) sockNumber: (int) num
{
    SockSprite *new_sprite = [SockSprite
                              spriteNodeWithTexture: currentShapesArray() [num]
                              size: CGSizeMake(40,60)];
    new_sprite.sock_number = num;
    new_sprite.out_of_play = NO;
    return new_sprite;
}

+ (int) totalSocks
{
    return (int)currentShapesArray().count;
}

+ (void)revealManyShapes: (BOOL) yn
{
    g_useManyShapes = yn;
}

- (void)startFlowWith: (CGFloat)new_speed turn:(CGFloat)degree
{
    self.fall_speed = new_speed;
    
    SKAction *move = [SKAction moveBy: CGVectorMake(0, -new_speed) duration:1];
    SKAction *spin = [SKAction rotateByAngle: degree duration:1];
    SKAction *move_spin = [SKAction repeatActionForever: [SKAction group:@[move, spin]]];
    
    [self runAction: move_spin];
}

- (void)stopFlow
{
    [self removeAllActions];
}

- (void)moveAwayByX:(CGFloat)x
                  y:(CGFloat)y
               with:(SockSprite*)other
        matchResult:(MatchedResult)match
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

    // score animation
    {
        SKLabelNode *plus = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        plus.fontSize = 20;
        plus.fontColor = [UIColor greenColor];
        plus.text = [NSString stringWithFormat: @"+%d", match.score];
        plus.position = self.position;
        SKAction *move_away = [SKAction moveTo:match.move_to duration:3];
        [plus runAction: [SKAction sequence:@[move_away, [SKAction removeFromParent]]]];
        [self.parent addChild: plus];
    }
    
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
    //SKAction *move_close1 = [SKAction moveByX: 50 y:50 duration: duration*.33];
    //SKAction *move_close2 = [SKAction moveByX: 50 y:50 duration: duration*.33];
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
    p.y -= self.fall_speed * future;
    
    return p;
}

@end
