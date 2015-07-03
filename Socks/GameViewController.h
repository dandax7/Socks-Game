//
//  ViewController.h
//  Socks
//

//  Copyright (c) 2014 dantap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <iAd/iAd.h>

@class SocksScene;
@class ScorePolicy;

@interface GameViewController : UIViewController<ADBannerViewDelegate>
{
    ScorePolicy *score_poly;
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
- (void) gameLost;
- (void) gameWon;


@end


