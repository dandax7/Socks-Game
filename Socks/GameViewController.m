//
//  ViewController.m
//  Socks
//
//  Created by Dan Akselrod on 3/23/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import "GameViewController.h"
#import "SocksScene.h"
#import "SockSprite.h"

@implementation GameViewController
@synthesize socksScene;
@synthesize skView;
@synthesize lost_lbl;
@synthesize score_lbl;
@synthesize cycle_rinse;
@synthesize cycle_spin;
@synthesize cycle_wash;

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    lost_socks = 0;
    score = 0;
    score_for_sock = 10;
    
    NSLog(@"appeared");
    
    // Configure the view.
    self.skView.showsFPS = YES;
    self.skView.showsNodeCount = YES;
    
    // self bounds
    CGRect bounds = self.skView.bounds;
    self.socksScene = [SocksScene sceneWithSize:bounds.size];
    self.socksScene.gameDelegate = self;
    [self.skView presentScene: self.socksScene];
    
    //self.socksScene.speed = 10;
    
    
    // start at rinse
    self.cycle_rinse.highlighted = YES;
}

- (void) sockLost
{
    ++lost_socks;
    lost_lbl.text = [NSString stringWithFormat:@"%d", lost_socks];

    return;
    
    const NSTimeInterval burst_time = 1;

    CGRect orig_frame = lost_lbl.frame;
    CGRect blow_frame = orig_frame;
    blow_frame.size.height *= 2;
    blow_frame.size.width *= 2;
    
   // void (^blow_up) = ^{lost_lbl.frame = blow_frame; };
   // void (^restore(BOOL)) = ^{lost_lbl.frame = orig_frame; };
   // [UIView animateWithDuration:burst_time/2
   //                  animations:^{lost_lbl.frame = blow_frame; }
   //                  completion:^(BOOL finished){{lost_lbl.frame = orig_frame;} } ];
}

- (void) socksMatched
{
    score += score_for_sock;
    score_lbl.text = [NSString stringWithFormat:@"%d", score];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

-(void)pauseUnpause:(id)button;
{
    [self.socksScene pauseUnpause: button];
}

@end
