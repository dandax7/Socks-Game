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
#import "ScorePolicy.h"

@implementation GameViewController
@synthesize socksScene;
@synthesize skView;
@synthesize lost_lbl;
@synthesize score_lbl;
@synthesize adView;


- (void)viewDidLoad
{
   // adView.delegate = self;

    [super viewDidLoad];
    
    self.gameOverBtn.hidden = YES;
        
    NSLog(@"appeared");
    
    // Configure the view.
    self.skView.showsFPS = YES;
    self.skView.showsNodeCount = YES;
    
    // score
    score_poly = [ScorePolicy firstScorePolicy];
    
    // self bounds
    CGRect bounds = self.skView.bounds;
    self.socksScene = [[SocksScene alloc] initWithSize:bounds.size
                                           scorePolicy:score_poly];
    GameViewController * __weak weakSelf = self;

    self.socksScene.doOnGameOver = ^{
        [weakSelf gameLost];
    };

    self.socksScene.doOnWin = ^{
        [weakSelf gameWon];
    };

    [self.skView presentScene: self.socksScene];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner
               willLeaveApplication:(BOOL)willLeave
{
    NSLog(@"bannerViewActionShouldBegin: %@ willLeave: %d loaded: %d",
          banner,
          willLeave,
          banner.isBannerLoaded);
    
    if (!banner.isBannerLoaded)
        return NO;
    
    if (!willLeave)
        [self.socksScene adPause];
    
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    NSLog(@"bannerViewActionDidFinish: %@", banner);
    [self.socksScene adUnpause];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"AD error: %@", error);
}

/*
- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    NSLog(@"Ad loaded banner: %@", banner);
}
*/

- (void) gameLost
{
    self.gameOverBtn.hidden = NO;
    self.gameOverBtn.highlighted = NO;

    [[ScoreManager sharedScoreManager] reportScore: score_poly.score];
}

- (void) gameWon
{
    self.gameOverBtn.hidden = NO;
    self.gameOverBtn.highlighted = YES;
    
    [[ScoreManager sharedScoreManager] reportScore: score_poly.score];
}

-(IBAction) gameOverPressed:(id)sender
{
    [self dismissViewControllerAnimated: YES completion: nil];
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
