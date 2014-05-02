//
//  ViewController.m
//  Socks
//
//  Created by Dan Akselrod on 3/23/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import "GameViewController.h"
#import "SocksScene.h"

@implementation GameViewController
@synthesize progressBar;

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    
    // self bounds
    CGRect bounds = skView.bounds;
    bounds.size.height -= 100;
    [skView setBounds:bounds];

    SKScene * progressScene = [SKScene sceneWithSize:bounds.size];
    progressScene.backgroundColor = [UIColor blueColor];
    [skView presentScene: progressScene];
    
    // Create and configure the scene.
    SocksScene * scene = [SocksScene sceneWithSize:bounds.size];
    scene.backgroundColor = [UIColor greenColor];
    scene.scaleMode = SKSceneScaleModeAspectFill;

    progressBar.hidden = NO;
    progressBar.progress = 0.0;

    // this block will bg load the texture
    
    float_callback progress = ^(float p){
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressBar setProgress: p];
        });
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [scene loadTextures: progress];
    
        // Present the scene. on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            progressBar.hidden = YES;
            [skView presentScene: scene transition: [SKTransition fadeWithDuration:2]];
        });
    });
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

@end
