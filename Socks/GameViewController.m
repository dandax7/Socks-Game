//
//  ViewController.m
//  Socks
//
//  Created by Dan Akselrod on 3/23/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import "GameViewController.h"
#import "ScoreManager.h"
#import "SocksScene.h"

@implementation GameViewController
@synthesize socksScene;
@synthesize skView;
@synthesize lost_lbl;
@synthesize score_lbl;
@synthesize adView;

- (void)viewDidLoad
{
    adView.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.gameOverBtn.hidden = YES;
    
    lost_socks = 20;
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
   
    [self startRinse];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner
               willLeaveApplication:(BOOL)willLeave
{
    // todo: pause
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    // todo: unpause
}

- (void)bannerView:(ADBannerView *)banner
didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"AD error: %@", error);
}

- (void) gameOver
{
    self.gameOverBtn.hidden = NO;    

    [[ScoreManager sharedScoreManager] reportScore: score];

    [self.socksScene gameOver];
}

-(IBAction) gameOverPressed:(id)sender
{
    [self removeFromParentViewController];
}

- (void)startRinse
{
    if (socksScene.isGameOver) return;

    [self.socksScene scheduleMessage:@"Rinse" completion:^{} ];

    score_for_sock = 10;
    self.socksScene.speed = 1;
    [self performSelector:@selector(startWash) withObject:nil afterDelay:20];
}

- (void)startWash
{
    if (socksScene.isGameOver) return;

    [self.socksScene scheduleMessage:@"Wash" completion:^{} ];

    score_for_sock = 20;
    self.socksScene.speed = 1.5;
    [self performSelector:@selector(startSpin) withObject:nil afterDelay:20];
}

- (void)startSpin
{
    if (socksScene.isGameOver) return;

    [self.socksScene scheduleMessage:@"Spin" completion:^{} ];

    score_for_sock = 40;
    self.socksScene.speed = 2;
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
    [UIView animateWithDuration:1 delay:0 usingSpringWithDamping:.2 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{v.center = new_center;} completion:nil];
}

- (MatchedResult) socksMatched
{
    score += score_for_sock;
    score_lbl.text = [NSString stringWithFormat:@"%d", score];
    CGPoint score_center = self.score_lbl.center;
    score_center = [self.score_lbl.superview
                        convertPoint: score_center
                        toView: skView];
    MatchedResult ret = {score_for_sock, score_center};
    return ret;
}

- (int) unmatchedSock
{
    score += score_for_sock/2;
    score_lbl.text = [NSString stringWithFormat:@"%d", score];
    return score_for_sock/2;
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
