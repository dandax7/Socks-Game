//
//  MyScene.m
//  Socks
//
//  Created by Dan Akselrod on 3/23/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import "SocksScene.h"
#import "SockSprite.h"
#import "SockMonster.h"
#import "Random.h"
#import "GameDelegate.h"

enum ColliosionBitMask
{
    SockMask = 0x1 << 0,
    WaterMask = 0x1 << 1,
};

const int PAUSE_STEPS = 10; // higher number causes longer pausing
const int WATER_HEIGHT = 60; // has to be higher then iAd bar, hard code for now

@implementation SocksScene
@synthesize gameDelegate;
@synthesize pause_lbl;

-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        last_create = 0;
        last_create_attempt = 0;
        system_paused = NO;
        button_paused = NO;
        game_over = NO;
        pause_steps_to_take = 0;
        unpause_steps_to_take = 0;
        last_frame_time = 0;
        running_time = 0;
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        self.scaleMode = SKSceneScaleModeAspectFill;

        // must be our bottom sprite, so gets added first
        [self flowBackground: size];
    
        CGSize water_size = CGSizeMake(size.width, WATER_HEIGHT);
        [self createWater: water_size];
        
        [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(systemPause) name: @"AppBg" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(systemUnpause) name: @"AppFg" object:nil];
    }
    
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL)isGameOver
{
    return game_over;
}

-(void)gameOver
{
    if (game_over)
    {
        NSLog(@"Game over twice???");
        return;
    }

    self.speed = .5;
    game_over = YES;

    // for some reason we have to do this 2nd part a tad later
    // otherwise speed of the socks flying off is wrong
    [self performSelectorOnMainThread:@selector(gameOverBg) withObject:nil waitUntilDone:NO ];
}

-(void)gameOverBg
{
    int child_count = 0;

    for (SKNode *child in [self children])
    {
        if ([child isKindOfClass: [SockSprite class]])
        {
            SockSprite *sock = (SockSprite*)child;
            int score = [gameDelegate unmatchedSock];
            [sock moveAwayByX: -self.size.width y:0 with:nil score: score duration:2];
            child_count++;
        }
    }
}

-(void)flowBackground: (CGSize) size
{
    SKSpriteNode *bg1 = [SKSpriteNode spriteNodeWithImageNamed: @"washer-drum-square.png"];
    SKSpriteNode *bg2 = [SKSpriteNode spriteNodeWithImageNamed: @"washer-drum-square.png"];
    SKSpriteNode *bg3 = [SKSpriteNode spriteNodeWithImageNamed: @"washer-drum-square.png"];

    CGFloat sq_size = self.size.width;
    bg3.size = bg2.size = bg1.size = CGSizeMake(sq_size, sq_size);
    
    //  overlap by a point to get rid of the moving seam
    CGPoint p1 = CGPointMake(self.size.width * .5, self.size.height - sq_size * (0 + .5));
    CGPoint p2 = CGPointMake(self.size.width * .5, self.size.height - sq_size * (1 + .5) + 1);
    CGPoint p3 = CGPointMake(self.size.width * .5, self.size.height - sq_size * (2 + .5) + 2);
    bg1.position = p1;
    bg2.position = p2;
    bg3.position = p3;
    SKAction *scroll_up = [SKAction moveByX:0 y:sq_size duration:10];
    SKAction *move_bottom_stack = [SKAction moveTo:p3 duration:0];
    SKAction *full_sequence = [SKAction repeatActionForever: [SKAction sequence:@[move_bottom_stack, scroll_up, scroll_up, scroll_up]]];
    
    [bg1 runAction: [SKAction sequence: @[scroll_up, full_sequence]]];
    [bg2 runAction: [SKAction sequence: @[scroll_up, scroll_up, full_sequence]]];
    [bg3 runAction: [SKAction sequence: @[scroll_up, scroll_up, scroll_up, full_sequence]]];
    [self addChild:bg1];
    [self addChild:bg2];
    [self addChild:bg3];
}

-(void)createWater:(CGSize)size
{
    UIColor* transparent =[UIColor colorWithRed:0 green:0.1 blue:0.9 alpha:0.5];
    SKSpriteNode *water = [SKSpriteNode spriteNodeWithColor: transparent size:size];
    water.position = CGPointMake(size.width/2, size.height/2);
    
    CGSize phys_size = size;
    phys_size.height *= .6;
    water.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize: phys_size];
    water.physicsBody.contactTestBitMask = SockMask;
    water.physicsBody.categoryBitMask = WaterMask;
    water.physicsBody.collisionBitMask = 0;
    
    [self addChild: water];
}

-(void)flowSock:(SockSprite*)sock
{
    CGFloat degree = arc4random_uniform_float(-M_PI_2, +M_PI_2, .01);
    CGFloat speed = 40; // TODO
    
    [sock startFlowWith:speed turn:degree];
}

- (BOOL)resignFirstResponder
{
    return [super resignFirstResponder];
}

- (void) physicsOnSock:(SockSprite *)sock
{
    sock.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:
                        CGSizeMake(sock.size.width * .9, sock.size.height * .9)];
    
    sock.physicsBody.mass = 0;
    sock.physicsBody.categoryBitMask = SockMask;
    sock.physicsBody.contactTestBitMask = SockMask;

    // we want the socks to go through each other
    sock.physicsBody.collisionBitMask = 0;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.paused) return;
    if (game_over) return;

    /* Called when a touch begins */
    for (UITouch *touch in touches)
    {
        CGPoint location = [touch locationInNode:self];

        // we move all socks at that location
        NSArray *touch_nodes = [self nodesAtPoint: location];
        for (SKNode *touch_node in touch_nodes)
        {
            if (![touch_node isKindOfClass:[SockSprite class]])
                continue;

            SockSprite *touch_sock = (SockSprite*) touch_node;
            if (touch_sock.out_of_play)
                continue;

            [touch_sock stopFlow];
            touch_sock.moving_touch = touch;
        }
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (game_over) return;

    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        BOOL moved_any = NO;
        // lets find socks moving by this touch
        for (SKNode *node in [self children]) {
            if (![node isKindOfClass: [SockSprite class]])
                continue;
            
            SockSprite *touch_sock = (SockSprite*) node;
            if (touch_sock.moving_touch == touch) {
                if (touch_sock.out_of_play)
                    continue;

                // move to finger
                moved_any = YES;
                touch_sock.position = location;
            }
        }
        
        // possibly, we've tried to move a sock but missed it,
        // and now moving through it, we should pick it up
        if (!moved_any) // maybe check time??
        {
            NSArray *pickups = [self nodesAtPoint:location];
            for (SKNode *pickup in pickups)
            {
                if (![pickup isKindOfClass: [SockSprite class]])
                    continue;
                
                SockSprite *pickup_sock = (SockSprite*) pickup;
                if (pickup_sock.moving_touch || pickup_sock.out_of_play)
                    continue; // already being moved or out of play, never mind
                
                // not moved yet, pick it up!
                [pickup_sock stopFlow];
                pickup_sock.moving_touch = touch;
                pickup_sock.position = location;
            }
        }
    }
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    return [self touchesEnded: touches withEvent: event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (game_over) return;

    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        /*
        // we need the socks at the old location, since we haven't moved them yet
        CGPoint old_location = [touch previousLocationInNode:self];
        // get them all since, the one we're moving might be behind another one
        NSArray *touch_nodes = [self nodesAtPoint: old_location];
        for (id touch_node in touch_nodes)
        {
         */
        for (SKNode *node in [self children])
        {
            if (![node isKindOfClass:[SockSprite class]])
                continue;
        
            SockSprite *touch_sock = (SockSprite*) node;
            if (touch_sock.moving_touch == touch) {
                touch_sock.moving_touch = nil;
                if (touch_sock.out_of_play)
                    continue;
                
                touch_sock.position = location;
                [self flowSock: touch_sock];
            }
        }
    }
}

- (void)socksMatched:(SockSprite*)sockA with:(SockSprite*)sockB
{
    NSLog(@"got sock contact between %d %d", sockA.sock_number, sockB.sock_number);
    
    if (sockA.sock_number != sockB.sock_number)
        return;
    
    sockA.out_of_play = YES;
    sockB.out_of_play = YES;
    
    int score = [gameDelegate socksMatched];
    [sockA moveAwayByX:-self.size.width y:0 with: sockB score: score duration:1.5];
    
    // TODO music
}

- (void)sockEnteredWater:(SockSprite*)sock
{
    NSLog(@"got contact between sock and water");
    
    SockMonster *monster = [SockMonster plainMonster: 40];
    monster.position = CGPointMake(sock.position.x, 0);
    [self addChild: monster];
    [monster animateSockEating:sock duration:1 completion: ^{[gameDelegate sockLost];}];
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    if (game_over) return;
    
    if (contact.bodyA.categoryBitMask & SockMask &&
        contact.bodyB.categoryBitMask & SockMask)
    {
        [self socksMatched:(SockSprite*)contact.bodyA.node
                      with:(SockSprite*)contact.bodyB.node];
     
    }
    else if (contact.bodyA.categoryBitMask & SockMask &&
             contact.bodyB.categoryBitMask & WaterMask)
    {
        [self sockEnteredWater:(SockSprite*)contact.bodyA.node];
    }
    else if (contact.bodyA.categoryBitMask & WaterMask &&
             contact.bodyB.categoryBitMask & SockMask)
    {
        [self sockEnteredWater:(SockSprite*)contact.bodyB.node];
    }
    else
    {
        NSLog(@"got unknown contact");
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
    
    NSUInteger exist_count = existing_socks.count;
    
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
        
        int rand_sock = (int)arc4random_uniform((uint32_t)existing_socks.count);
        NSLog(@"Creating same as existing sock number %d (of %lu)", rand_sock, existing_socks.count);

        SockSprite *rand_sock_obj = existing_socks[rand_sock];
        return rand_sock_obj.sock_number;
    }
    
    NSLog(@"Creating random sock");
    return arc4random_uniform([SockSprite totalSocks]);
}

-(void)update:(CFTimeInterval)currentTime
{
    /* Called before each frame is rendered */
    CFTimeInterval timeDelta = currentTime - last_frame_time;
    last_frame_time = currentTime;

    if (system_paused) return;
    if (game_over) return;
    
    if (button_paused)
    {
        if (pause_steps_to_take > 0)
        {
            --pause_steps_to_take;
            [self pausingStep: +1];
            
            // a small race cond may increase unpause_steps_to_take
            // even as we're still pausing, so we return here
        }
        else if (unpause_steps_to_take > 0)
        {
            --unpause_steps_to_take;
            [self pausingStep: -1];
            
            if (unpause_steps_to_take == 0)
            {
                self.paused = NO; // unpause now
                button_paused = NO;
            }
        }
        
        return;
    }
    
    // not paused
    running_time += timeDelta;
    
    if (last_create_attempt == 0 ||
        running_time - last_create_attempt > 2)
    {
        last_create_attempt = running_time;
        
        int sock_no = [self pickASock];
        if (sock_no < 0)
            return; // no sock this time
        
        last_create = running_time;
        
        CGFloat at_x = arc4random_uniform(self.size.width - 80) + 30;
        CGPoint pos = CGPointMake(at_x, self.size.height);
        
        //NSLog(@"Creating sock sprite number %d at (%d, %d)", sock_no, (int)pos.x, (int)pos.y);
        
        SockSprite *sock = [SockSprite sockNumber: sock_no];
        
        sock.position = pos;        
        [self flowSock: sock];
        [self physicsOnSock:sock];
        [self addChild:sock];
    }
}

- (void)pausingStep: (int) direction
{
    // called from update as we're pausing
    // direction is either +1 or -1
    
    for (id child in [self children])
    {
        if (![child isKindOfClass: [SockSprite class]])
            continue;
        
        SockSprite* sock = (SockSprite*)child;
        CGPoint pos = sock.position;
        pos.x += sock.pause_speed.x * direction;
        pos.y += sock.pause_speed.y * direction;
        sock.position = pos;
    }
}

- (void)systemPause
{
    system_paused = YES;
    self.paused = YES;
    // if we're paused, stay paused
    // if we're pausing, keep pausing
    // if we're system paused, stay that way
}

- (void)systemUnpause
{
    system_paused = NO;
    self.paused = button_paused;
}

- (void)pauseUnpause: (id)sender
{
    if (system_paused) return;
    if (game_over) return;
    
    BOOL to_pause = !button_paused;
    
    UIButton *btn = (UIButton*)sender;
    
    if (!to_pause && (unpause_steps_to_take != 0 || pause_steps_to_take != 0))
        return; // we have more steps to take

    btn.selected = to_pause;

    if (to_pause)
    {
        pause_steps_to_take = PAUSE_STEPS;
        unpause_steps_to_take = 0;
        self.paused = YES;
        button_paused = YES;

        // move socks to the sides
        int park_at_y = self.size.height - 40;
        int park_at_x = 20;
        
        for (id child in [self children])
        {
            if (![child isKindOfClass: [SockSprite class]])
                continue;

            SockSprite* sock = (SockSprite*)child;
            sock.pause_saved_position = sock.position;
            sock.pause_speed = CGPointMake((park_at_x - sock.pause_saved_position.x) / PAUSE_STEPS,
                                           (park_at_y - sock.pause_saved_position.y) / PAUSE_STEPS);
            
            if (park_at_x == 20)
            {
                park_at_x = self.size.width-20;
            }
            else
            {
                park_at_x = 20;
                park_at_y = (park_at_y - 60 + (int)self.size.height) % (int)self.size.height;
            }
        }
        
        // tell user we're paused
        self.pause_lbl = [SKLabelNode labelNodeWithFontNamed: @"Marker Felt Thin"];
        [self.pause_lbl setText:@"PAUSED"];
        self.pause_lbl.position = CGPointMake(self.size.width/2, self.size.height/2);
        [self addChild: self.pause_lbl];
    }
    else
    {
        unpause_steps_to_take = PAUSE_STEPS;
        
        // remove the label
        [self.pause_lbl removeFromParent];
        self.pause_lbl = nil;
        
        // don't unpause ourselves, til all steps were reversed;
    }
}

@end
