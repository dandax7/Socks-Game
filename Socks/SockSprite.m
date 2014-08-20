//
//  SockSprite.m
//  Socks
//
//  Created by Dan Akselrod on 3/30/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import "SockSprite.h"

static NSMutableArray *g_sockTextures;

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

    g_sockTextures = [[NSMutableArray alloc]initWithCapacity: (socks_end - 1) * (pattern_end - 1)];
    
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
            [g_sockTextures addObject: sock_txture];
            CGImageRelease(cgImage);
            
            progress_cb(++done/ total);
        }
    }
}

+ (SockSprite*) sockNumber: (int) num
{
    SockSprite *new_sprite = [SockSprite
                              spriteNodeWithTexture: g_sockTextures[num]
                              size: CGSizeMake(40,60)];
    new_sprite.sock_number = num;
    new_sprite.out_of_play = NO;
    return new_sprite;
}

+ (int) totalSocks
{
    return g_sockTextures.count;
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
              score:(int)score
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

    // put the other sock close to us
    other.position = CGPointMake(self.position.x - 8,
                                 self.position.y + 12);

    // score animation
    SKLabelNode *plus = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    plus.fontSize = 20;
    plus.fontColor = [UIColor greenColor];
    plus.text = [NSString stringWithFormat: @"+%d", score];
    plus.position = self.position;
    SKAction *blow_up = [SKAction scaleBy: 2 duration:3];
    SKAction *disappear = [SKAction fadeAlphaTo:0 duration:3];
    SKAction *explode = [SKAction group: @[blow_up, disappear]];
    [plus runAction: [SKAction sequence:@[explode, [SKAction removeFromParent]]]];
    [self.parent addChild: plus];

    // sock animation
    SKAction *move_away = [SKAction moveByX: x y:y duration:duration * .66];
    SKAction *straight = [SKAction rotateToAngle:0 duration:duration * .33];
    SKAction *exit = [SKAction sequence: @[straight, move_away, [SKAction removeFromParent]]];

    [self runAction: exit];
    [other runAction: exit];
}

- (CGPoint)futurePoint:(NSTimeInterval)future
{
    CGPoint p = self.position;
    p.y -= self.fall_speed * future;
    
    return p;
}

@end
