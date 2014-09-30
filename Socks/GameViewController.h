//
//  ViewController.h
//  Socks
//

//  Copyright (c) 2014 dantap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <iAd/iAd.h>
#import "GameDelegate.h"

@class SocksScene;

@interface GameViewController : UIViewController<GameDelegate, ADBannerViewDelegate>
{
    int lost_socks;
    int score;
    int score_for_sock;
}
@property (nonatomic,retain) SocksScene* socksScene;

@property (nonatomic,retain) IBOutlet SKView *skView;
@property (nonatomic,retain) IBOutlet UIButton *pauseBtn;
@property (nonatomic,retain) IBOutlet UIButton *gameOverBtn;

@property (nonatomic,retain) IBOutlet UILabel *lost_lbl;
@property (nonatomic,retain) IBOutlet UILabel *score_lbl;
@property (nonatomic,retain) IBOutlet ADBannerView *adView;

-(IBAction) gameOverPressed:(id)sender;
-(IBAction) pauseUnpause:(id)button;
- (void) sockLost;
- (int) socksMatched;
- (int) unmatchedSock;
- (void) gameOver;


@end


