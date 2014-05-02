//
//  MyScene.m
//  Socks
//
//  Created by Dan Akselrod on 3/23/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import "SocksScene.h"
#import "SockSprite.h"
#import "Random.h"

enum ColliosionBitMask
{
    SockMask = 0x1
};


@implementation SocksScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        last_create = 0;
        last_create_attempt = 0;
        
        for (pattern_end = 1;;pattern_end++) {
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
    }
    
    return self;
}

-(void)loadTextures:(float_callback) progress_cb
{
    sockTextures = [[NSMutableArray alloc]initWithCapacity: (socks_end - 1) * (pattern_end - 1)];
    
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
            [sockTextures addObject: sock_txture];
            CGImageRelease(cgImage);
 
            progress_cb(++done/ total);
        }
    }
    
    self.physicsWorld.gravity = CGVectorMake(0, 0);
    self.physicsWorld.contactDelegate = self;
    
    last_create = 0;
}

-(void)flowSock:(SockSprite*)sock
{
    CGFloat degree = arc4random_uniform_float(-M_PI_2, +M_PI_2, .01);
    CGSize size = self.size;
    CGPoint pos = sock.position;
    CGFloat duration = 13 + 10.0 * (pos.x / (CGFloat)size.width);
    SKAction *sock_move = [SKAction moveToY:0 duration: duration];
    [sock runAction: [SKAction rotateByAngle: degree duration:duration]
            withKey: @"rotate"];
    [sock runAction: [SKAction sequence: @[sock_move,
                                           [SKAction removeFromParent]]]
                                            withKey: @"flow"];
}

- (void) physicsOnSock:(SockSprite *)sock
{
    sock.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize: CGSizeMake(sock.size.width * .2,
                                                                          sock.size.height * .2)];
    
    sock.physicsBody.mass = 0;
    sock.physicsBody.categoryBitMask = SockMask;
    sock.physicsBody.collisionBitMask = 0;// we want the socks to go through each other
    sock.physicsBody.contactTestBitMask = SockMask;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    /* Called when a touch begins */
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];

        SKNode *touch_node = [self nodeAtPoint: location];
        if (touch_node == nil)
            continue;
        if (![touch_node isKindOfClass:[SockSprite class]])
            continue;

        SockSprite *touch_sock = (SockSprite*) touch_node;
        [touch_sock runAction: nil withKey: @"flow"];
        touch_sock.moving_touch = touch;
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        CGPoint old_location = [touch previousLocationInNode:self];
        
        NSArray *touch_nodes = [self nodesAtPoint: old_location];
        for (id touch_node in touch_nodes)
        {
            if (![touch_node isKindOfClass:[SockSprite class]])
                continue;
            SockSprite *touch_sock = (SockSprite*) touch_node;
            if (touch_sock.moving_touch == touch) {
                CGPoint pos = touch_sock.position;
                pos.x += (location.x - old_location.x);
                pos.y += (location.y - old_location.y);
                touch_sock.position = pos;
            }
        }
    }
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    return [self touchesEnded: touches withEvent: event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        CGPoint old_location = [touch previousLocationInNode:self];
        
        NSArray *touch_nodes = [self nodesAtPoint: old_location];
        for (id touch_node in touch_nodes)
        {
            if (![touch_node isKindOfClass:[SockSprite class]])
                continue;
            SockSprite *touch_sock = (SockSprite*) touch_node;
            if (touch_sock.moving_touch == touch) {
                CGPoint pos = touch_sock.position;
                pos.x += (location.x - old_location.x);
                pos.y += (location.y - old_location.y);
                touch_sock.position = pos;
                
                touch_sock.moving_touch = nil;
                [self flowSock: touch_sock];
            }
        }
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    if (contact.bodyA.categoryBitMask & SockMask &&
        contact.bodyB.categoryBitMask & SockMask)
    {
        SockSprite *sockA = (SockSprite*)contact.bodyA.node;
        SockSprite *sockB = (SockSprite*)contact.bodyB.node;
     
        NSLog(@"got sock contact between %d %d", sockA.sock_number, sockB.sock_number);

        if (sockA.sock_number == sockB.sock_number)
        {
            // TODO animate + music
            [sockA removeFromParent];
            [sockB removeFromParent];
        }
    }
}

-(int)pickASock
{
    NSMutableArray *existing_socks = [NSMutableArray array];
    for (id child in [self children])
    {
        if ([child isKindOfClass: [SockSprite class]])
            [existing_socks addObject: child];
    }
    
    int exist_count = existing_socks.count;
    
    //NSLog(@"pickAsock called w/ count %d", exist_count);
    
    float prob_create;
    float prob_existing;
    switch (exist_count) {
        case 0:
            prob_create = 1;
            prob_existing = 0;
            break;
        case 1:
            prob_create = .5;
            prob_existing = 0;
            break;
        default:
            prob_create = .1 + last_create / 5;
            prob_existing = .2;
            break;
    }
    
    if (!arc4random_boolean(prob_create))
    {
        NSLog(@"Not creating one");
        return -1;
    }

    if (arc4random_boolean(prob_existing))
    {
        // return one of the socks we have
        
        int rand_sock = arc4random_uniform(existing_socks.count);
        NSLog(@"Creating same as existing sock number %d (of %d)", rand_sock, existing_socks.count);

        SockSprite *rand_sock_obj = existing_socks[rand_sock];
        return rand_sock_obj.sock_number;
    }
    
    NSLog(@"Creating random sock");
    return arc4random_uniform(sockTextures.count);
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    if (last_create_attempt == 0 ||
        currentTime - last_create_attempt > 2)
    {
        last_create_attempt = currentTime;
        
        int sock_no = [self pickASock];
        if (sock_no < 0)
            return; // no sock this time
        
        last_create = currentTime;
        
        CGFloat at_x = arc4random_uniform(self.size.width - 80) + 30;
        CGPoint pos = CGPointMake(at_x, self.size.height);
        
        //NSLog(@"Creating sock sprite number %d at (%d, %d)", sock_no, (int)pos.x, (int)pos.y);
        
        SockSprite *sock = [SockSprite
                            spriteNodeWithTexture: sockTextures[sock_no]
                            size: CGSizeMake(40,60)];
        sock.position = pos;
        sock.sock_number = sock_no;
        
        [self flowSock: sock];
        [self physicsOnSock:sock];
        [self addChild:sock];
    }
}

@end
