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
    
    self.gameOverBtn.hidden = YES;
    
    lost_socks = 10;
    lost_lbl.text = [NSString stringWithFormat:@"%d", lost_socks];

    score = 0;
    score_lbl.text = [NSString stringWithFormat:@"%d", score];

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
    
    // start at rinse
    [self startRinse];
}

- (void) gameOver
{
    self.socksScene.speed = 1;
    self.gameOverBtn.hidden = NO;
    [self.socksScene gameOver];
}

-(IBAction) gameOverPressed:(id)sender
{

}

- (void)startRinse
{
    self.socksScene.speed = 1;
    self.cycle_rinse.highlighted = YES;
    self.cycle_wash.highlighted = NO;
    self.cycle_spin.highlighted = NO;
    [self performSelector:@selector(startWash) withObject:nil afterDelay:20];
}

- (void)startWash
{
    self.socksScene.speed = 1.5;
    self.cycle_rinse.highlighted = NO;
    self.cycle_wash.highlighted = YES;
    self.cycle_spin.highlighted = NO;
    [self performSelector:@selector(startSpin) withObject:nil afterDelay:20];
}

- (void)startSpin
{
    self.socksScene.speed = 2;
    self.cycle_rinse.highlighted = NO;
    self.cycle_wash.highlighted = NO;
    self.cycle_spin.highlighted = YES;
    [self performSelector:@selector(startRinse) withObject:nil afterDelay:20];
}

- (void) sockLost
{
    if (lost_socks)
        --lost_socks;

    lost_lbl.text = [NSString stringWithFormat:@"%d", lost_socks];
    [self shake: lost_lbl];
    
    if (lost_socks <= 0)
        [self gameOver];
}

- (void) shake: (UIView*) v
{
    CGPoint old_center = v.center;
    CGPoint new_center = CGPointMake(old_center.x + 20, old_center.y);
    [UIView animateWithDuration:1 delay:0 usingSpringWithDamping:.2 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{v.center = new_center;v.center = old_center;} completion:nil];
}

- (int) socksMatched
{
    score += score_for_sock;
    score_lbl.text = [NSString stringWithFormat:@"%d", score];
    return score_for_sock;
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
