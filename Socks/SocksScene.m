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
#import "ScorePolicy.h"

enum ColliosionBitMask
{
    SockMask = 0x1 << 0,
    WaterMask = 0x1 << 1,
};

const int PAUSE_STEPS = 10; // higher number causes longer pausing
const int WATER_HEIGHT = 75; // has to be higher then iAd bar, hard code for now
const int SCORE_LIVES_OFFSET = 20;
const int LIVES_PIXEL_HEIGHT = 10;
const int LIVES_PIXEL_WIDTH = 7.3;
const int LIVES_MAX_IN_ROW = 5;

@implementation SocksScene
@synthesize score_label;
@synthesize score_shadow;
@synthesize pause_lbl;

-(instancetype) initWithSize:(CGSize) size scorePolicy: (ScorePolicy*)spoly
{
    if (self = [super initWithSize:size])
    {
        score_policy = spoly;
        
        last_create = 0;
        last_create_attempt = 0;
        
        // pause state
        ad_paused = NO;
        system_paused = NO;
        button_paused = NO;
        saved_speed = 0.0;
        
        game_over = NO;
        did_win = NO;
        pause_steps_to_take = 0;
        unpause_steps_to_take = 0;
        last_frame_time = 0;
        running_time = 0;
        shapes = 1;
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        self.scaleMode = SKSceneScaleModeAspectFill;

        // must be our bottom sprite, so gets added first
        [self flowBackground: size];
    
        CGSize water_size = CGSizeMake(size.width, WATER_HEIGHT);
        [self createWater: water_size];
        
        [self populateSockLives];
        
        CGPoint score_pos =CGPointMake(self.size.width - SCORE_LIVES_OFFSET,
                                       self.size.height - SCORE_LIVES_OFFSET);
        [self createScoreLabelsAt: score_pos];
        
        [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(systemPause) name: @"AppBg" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(systemUnpause) name: @"AppFg" object:nil];
    
        // schedule a cycle
        next_cycle = 0;
    }
    
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)checkAllPauses
{
    if (game_over)
        return;
    
    if (ad_paused || system_paused || button_paused)
    {
        if (self.speed == 0.0)
            return; // already paused
        saved_speed = self.speed;
        self.speed = 0.0;  // unfortunately we can't trust .paused property
    }
    else
    {
        if (saved_speed == 0.0)
        {
            NSLog(@"Need to unpause but no saved speed");
            return;
        }
        self.speed = saved_speed;
        saved_speed = 0.0;
        
        // possibly some socks were being moved as we were pausing
        [self cancelAllTocuhes];
    }
}

-(BOOL)isInPlay
{
    return (!game_over && saved_speed == 0);
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
    for (SKNode *child in [self children])
    {
        if ([child isKindOfClass: [SockSprite class]])
        {
            SockSprite *sock = (SockSprite*)child;
            int score_delta = [score_policy unmatchedSockPoints];
            [self floatScoreLabel:score_delta from: sock.position];
            [sock moveAwayByX: -self.size.width y:0 with:nil duration:2];
        }
    }
    
    self.doOnGameOver();
}


-(void) populateSockLives
{
    sock_lives = [NSMutableArray arrayWithCapacity: score_policy.lives];
    SKTexture *plain_sock = [SKTexture textureWithImageNamed: @"sock-plain-small-red.png"];
    for (int i = 0; i < score_policy.lives; ++i)
    {
        SKSpriteNode *life_sock = [SKSpriteNode spriteNodeWithTexture: plain_sock size:CGSizeMake(LIVES_PIXEL_WIDTH, LIVES_PIXEL_HEIGHT)];
        
        // withing the box
        CGFloat x =(i % LIVES_MAX_IN_ROW) * LIVES_PIXEL_WIDTH;
        CGFloat y =(i / LIVES_MAX_IN_ROW) * LIVES_PIXEL_HEIGHT;
        // now the box
        x += SCORE_LIVES_OFFSET;
        y = self.size.height - SCORE_LIVES_OFFSET - y;
        
        life_sock.position = CGPointMake(x, y);
        life_sock.zPosition = 99;
        [self addChild: life_sock];
        [sock_lives addObject: life_sock];
    }
}

-(void) createScoreLabelsAt: (CGPoint) score_pos
{
    self.score_label = [SKLabelNode labelNodeWithFontNamed: @"Helvetica Neue Condensed Bold"];
    self.score_shadow = [SKLabelNode labelNodeWithFontNamed: @"Helvetica Neue Condensed Bold"];
    
    self.score_label.fontColor = [SKColor greenColor];
    self.score_shadow.fontColor = [SKColor blackColor];
    
    self.score_label.fontSize = 25;
    self.score_shadow.fontSize = 25;
    
    self.score_label.zPosition = 101;
    self.score_shadow.zPosition = 100;
    
    [self increaseScoreBy: 0];
    
    [self addChild: self.score_label];
    // at this point the frame size of the label should be calculated
    self.score_label.position =
        CGPointMake(score_pos.x,//  looks better that way, dunno why
                    score_pos.y - self.score_label.frame.size.height/2);
    
    [self addChild: self.score_shadow];
    self.score_shadow.position = CGPointMake(self.score_label.position.x + 2,
                                             self.score_label.position.y - 2);
}

-(void)runCycle
{
    [score_policy nextCycle];
    shapes = score_policy.shapesCount;
    if (shapes > [SockSprite maxShapes])
    {
        did_win = YES;
        [self gameOver];
    }
    self.speed = score_policy.animationSpeed;
    next_cycle = running_time + score_policy.cycleTime;
    [self scheduleMessage: score_policy.cycleName ];
}

-(void) increaseScoreBy: (int) delta
{
    score_policy.score = score_policy.score + delta;
    NSString *str = [NSString stringWithFormat:@"%d", score_policy.score];
    [self.score_label setText: str];
    [self.score_shadow setText: str];
}

-(void)flowBackground: (CGSize) size
{
    CGFloat sq_side = self.size.width;
    CGSize sq_size = CGSizeMake(sq_side, sq_side);

    SKTexture *drum = [SKTexture textureWithImageNamed: @"washer-drum-square.png"];
    SKSpriteNode *bg1 = [SKSpriteNode spriteNodeWithTexture:drum size:sq_size];
    SKSpriteNode *bg2 = [SKSpriteNode spriteNodeWithTexture:drum size:sq_size];
    SKSpriteNode *bg3 = [SKSpriteNode spriteNodeWithTexture:drum size:sq_size];
    
    //  overlap by a point to get rid of the moving seam
    CGPoint p1 = CGPointMake(self.size.width * .5, self.size.height - sq_side * (0 + .5));
    CGPoint p2 = CGPointMake(self.size.width * .5, self.size.height - sq_side * (1 + .5) + 1);
    CGPoint p3 = CGPointMake(self.size.width * .5, self.size.height - sq_side * (2 + .5) + 2);
    bg1.position = p1;
    bg2.position = p2;
    bg3.position = p3;
    SKAction *scroll_up = [SKAction moveByX:0 y:sq_side duration:10];
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
    SKTexture* wave = [SKTexture textureWithImageNamed: @"wave8.png"];
    SKSpriteNode *water1 = [SKSpriteNode spriteNodeWithTexture: wave];
    SKSpriteNode *water2 = [SKSpriteNode spriteNodeWithTexture: wave];
    SKSpriteNode *water3 = [SKSpriteNode spriteNodeWithTexture: wave];
    SKSpriteNode *water4 = [SKSpriteNode spriteNodeWithTexture: wave];

    // lets match the water height to our hight, but width will be longer
    CGFloat scale_fact = size.height / water1.size.height;
    CGSize water_size = water1.size;
    water1.size = CGSizeMake(water_size.width * scale_fact, water_size.height * scale_fact);
    water1.position = CGPointMake(size.width/2, size.height/2);
    
    // same size/position
    water2.size = water1.size;    water2.position = water1.position;
    water3.size = water1.size;    water3.position = water1.position;
    water4.size = water1.size;    water4.position = water1.position;
    
    // contants should only be on one of them
    CGSize phys_size = water1.size;
    phys_size.height *= .6;
    water1.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize: phys_size];
    water1.physicsBody.contactTestBitMask = SockMask;
    water1.physicsBody.categoryBitMask = WaterMask;
    water1.physicsBody.collisionBitMask = 0;

    CGFloat fwd_speed = 30;
    
    // sine wave
    SKAction *move_wave = [SKAction sequence: @[[SKAction moveByX: fwd_speed y: - 2.9 duration:.5],
                                                [SKAction moveByX: fwd_speed y: - 1.5 duration:.5],
                                                [SKAction moveByX: fwd_speed y: - 1.0 duration:.5],
                                                [SKAction moveByX: fwd_speed y: 0 duration:.5],
                                                [SKAction moveByX: fwd_speed y: 1.0 duration:.5],
                                                [SKAction moveByX: fwd_speed y: 1.5 duration:.5],
                                                [SKAction moveByX: fwd_speed y: 2.9 duration:.5],
                                                [SKAction moveByX: fwd_speed y: 0 duration:.5]]];
    SKAction *move_wave_back = [move_wave reversedAction];
    SKAction *move_wave_back_forth = [SKAction sequence: @[move_wave, move_wave_back]];
    
    [water1 runAction: [SKAction repeatActionForever: move_wave_back_forth]];
    water1.speed = .2;
    water1.alpha = .9;
    [water2 runAction: [SKAction repeatActionForever: move_wave_back_forth]];
    water2.speed = .3;
    water2.alpha = .9;
    [water3 runAction: [SKAction repeatActionForever: move_wave_back_forth]];
    water3.speed = .5;
    water3.alpha = .9;
    [water4 runAction: [SKAction repeatActionForever: move_wave_back_forth]];
    water4.speed = .7;
    water4.alpha = .9;
    [self addChild: water1];
    [self addChild: water2];
    [self addChild: water3];
    [self addChild: water4];
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

-(void)scheduleMessage:(NSString*)message
{
    last_create_attempt = running_time + 4; // don't create while we have a msg
    SKLabelNode *msg = [SKLabelNode labelNodeWithFontNamed: @"Marker Felt Thin"];
    [msg setText:message];
    msg.position = CGPointMake(self.size.width/2, self.size.height);
    [msg runAction: [SKAction sequence: @[[SKAction moveToY:0 duration:6],
                                          [SKAction removeFromParent]]]];
    [self addChild: msg];
    
    SKEmitterNode *bubbles = [SKEmitterNode nodeWithFileNamed: @"Bubbles"];
    bubbles.position = msg.position;
    bubbles.particlePositionRange = CGVectorMake(msg.frame.size.width, msg.frame.size.height);
    [bubbles runAction: [SKAction sequence: @[[SKAction moveToY:0 duration:6],
                                              [SKAction moveToY:-WATER_HEIGHT duration:1],
                                              [SKAction removeFromParent]]]];
    [self addChild: bubbles];

}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.isInPlay) return;

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
            break; // one sock at a time
        }
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.isInPlay) return;

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
            moved_any = YES; 
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
        
        for (SKNode *node in [self children])
        {
            if (![node isKindOfClass:[SockSprite class]])
                continue;

            SockSprite *touch_sock = (SockSprite*) node;
            if (touch_sock.moving_touch == touch) {
                touch_sock.moving_touch = nil;
        
                if (touch_sock.out_of_play || !self.isInPlay)
                    continue;
                
                touch_sock.position = location;
                [self flowSock: touch_sock];
            }
        }
    }
}

-(void)cancelAllTocuhes
{
    for (SKNode *node in [self children])
    {
        if (![node isKindOfClass:[SockSprite class]])
            continue;
        
        SockSprite *touch_sock = (SockSprite*) node;
        if (touch_sock.moving_touch != nil) {
            touch_sock.moving_touch = nil;
        }
        
        if (touch_sock.out_of_play || !self.isInPlay)
            continue;

        if (!touch_sock.is_flowing)
            [self flowSock: touch_sock];
    }
}

- (void)socksMatched:(SockSprite*)sockA with:(SockSprite*)sockB
{
    if (![sockA sameTypeAs: sockB])
        return;
    
    int score_delta = [score_policy matchedSockPoints];
    [self floatScoreLabel: score_delta from: sockA.position];
    [sockA moveAwayByX:-self.size.width y:0 with: sockB duration:1.5];
    
    // TODO music
}

- (void)floatScoreLabel:(int)score from: (CGPoint) pos
{
    // score animation
    SKLabelNode *plus = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    plus.fontSize = 20;
    plus.fontColor = [UIColor greenColor];
    plus.text = [NSString stringWithFormat: @"+%d", score];
    plus.position = pos;
    SKAction *move_away = [SKAction moveTo: self.score_label.position duration:3];
    SKAction *add_score = [SKAction runBlock:^{[self increaseScoreBy: score];}];
    [plus runAction: [SKAction sequence:@[move_away,
                                          add_score,
                                          [SKAction removeFromParent]]]];
    [self addChild: plus];
}

- (void) lostALife
{
    BOOL quitting = [score_policy lostALife];

    if (sock_lives.count)
    {
        SKSpriteNode *losing_sock = [sock_lives lastObject];
        [sock_lives removeLastObject];
        SKAction *expand = [SKAction scaleBy: 4 duration:2];
        SKAction *dissolve = [SKAction fadeAlphaTo: 0 duration:2];
        SKAction *blow_up = [SKAction group: @[expand, dissolve]];
        SKAction *blow_up_die = [SKAction sequence: @[blow_up,
                                                      [SKAction removeFromParent]]];
        [losing_sock runAction: blow_up_die];
    }
    else
    {
        if (!quitting) NSLog(@"Something is fishy, no more sock lives, but not quitting");
    }
    
    if (quitting)
        [self gameOver];
}

- (void)sockEnteredWater:(SockSprite*)sock
{
    NSLog(@"got contact between sock and water");
    
    SockMonster *monster = [SockMonster plainMonster: 40];
    monster.position = CGPointMake(sock.position.x, 0);
    [self addChild: monster];
    [monster animateSockEating:sock duration:1
                    completion: ^{[self lostALife];}];
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    if (!self.inPlay) return;
    
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

-(SockId)pickASock
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
        return MakeNullSockId();
    }

    if (arc4random_boolean(prob_existing))
    {
        // return one of the socks we have
        
        int rand_sock = (int)arc4random_uniform((uint32_t)existing_socks.count);
        NSLog(@"Creating same as existing sock number %d (of %lu)",
              rand_sock,
              (unsigned long)existing_socks.count);

        SockSprite *rand_sock_obj = existing_socks[rand_sock];
        return rand_sock_obj.sock_id;
    }
    
    NSLog(@"Creating random sock");
    return [SockSprite pickRandomId: shapes];
}

-(void)update:(CFTimeInterval)currentTime
{
    /* Called before each frame is rendered */
    CFTimeInterval timeDelta = currentTime - last_frame_time;
    last_frame_time = currentTime;

    if (!self.isInPlay)
    {
        // maybe it's pausing/unpausing
        
        if (!button_paused)
            return; // nope

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
                button_paused = NO;
                [self checkAllPauses]; // should resume if no other pauses
            }
        }
        
        return;
    }
    
    // not paused by anyone
    running_time += timeDelta;
    
    if (running_time > next_cycle)
        [self runCycle];
    
    if (running_time - last_create_attempt > 1)
    {
        last_create_attempt = running_time;
        
        SockId sid = [self pickASock];
        if (isNullSockId(sid))
            return; // no sock this time
        
        last_create = running_time;
        
        CGFloat at_x = arc4random_uniform(self.size.width - 80) + 30;
        CGPoint pos = CGPointMake(at_x, self.size.height);
        
        //NSLog(@"Creating sock sprite number %d at (%d, %d)", sock_no, (int)pos.x, (int)pos.y);
        
        SockSprite *sock = [SockSprite sockWithSockId: sid];
        
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
    [self checkAllPauses];
}

- (void)systemUnpause
{
    system_paused = NO;
    [self checkAllPauses];
}

- (void)adPause
{
    ad_paused = YES;
    [self checkAllPauses];
}

- (void)adUnpause
{
    ad_paused = NO;
    [self checkAllPauses];
}

- (void)pauseUnpause: (id)sender
{
    // the only reason we take this signal if we're out of play
    // is if's to unpause1
    
    // button_paused > yes > continue
    // \> no > inPlay -> yes -> continue
    //           \> return
    
    if (!self.inPlay && !button_paused)
        return;
    
    BOOL to_pause = !button_paused; // reverse
    
    UIButton *btn = (UIButton*)sender;
    
    if (!to_pause && (unpause_steps_to_take != 0 || pause_steps_to_take != 0))
        return; // we have more steps to take, cant' reverse now

    btn.selected = to_pause;

    if (to_pause)
    {
        // set the state for paused by button
        pause_steps_to_take = PAUSE_STEPS;
        unpause_steps_to_take = 0;
        button_paused = YES;
        
        [self checkAllPauses];

        // calculate socks' positions at the sides
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
        self.pause_lbl.fontColor = [SKColor redColor];
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
