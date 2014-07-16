//
//  MainViewController.m
//  Socks
//
//  Created by Dan Akselrod on 4/18/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import "MainViewController.h"
#import "SockSprite.h"

@interface MainViewController ()
@end


@implementation MainViewController
@synthesize progressBar;
@synthesize startBtn;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    // this block will bg load the texture
    
    float_callback progress = ^(float p){
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressBar setProgress: p];
        });
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [SockSprite loadTextures: progress];
        
        // Present the scene. on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            startBtn.enabled = YES;
        });
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
