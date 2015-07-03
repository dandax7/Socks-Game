//
//  MainViewController.m
//  Socks
//
//  Created by Dan Akselrod on 4/18/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import "MainViewController.h"
#import "SockSprite.h"
#import "ScoreManager.h"

#define SWITCH_MESSAGE_SHOW_AFTER 3.0
#define SWITCH_MESSAGE_SHOW_DURATION 1.0

@interface MainViewController ()
@end


@implementation MainViewController
@synthesize progressBar;
@synthesize startBtn;
@synthesize scoreHighest;
@synthesize scoreLast;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    //whatever
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    startBtn.enabled = NO;
    
    ScoreManager *sm = [ScoreManager sharedScoreManager];
    
    scoreLast.text = [NSString stringWithFormat:@"%d", sm.lastScore];
    scoreHighest.text = [NSString stringWithFormat:@"%d", sm.highestScore];
    
    // this block will bg load the texture
    
    float_callback progress = ^(float p){
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressBar setProgress: p];
        });
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [SockSprite loadTextures: progress];
        
        // Change buttons on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            startBtn.enabled = YES;
        });
        
    });
}

/*
- (void)viewDidAppear:(BOOL)animated
{
    
}
 */

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"Main AD error: %@", error);
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
