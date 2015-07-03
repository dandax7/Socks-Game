//
//  MainViewController.h
//  Socks
//
//  Created by Dan Akselrod on 4/18/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>

@interface MainViewController : UIViewController<ADBannerViewDelegate>
{
}

@property (nonatomic, retain) IBOutlet UIProgressView *progressBar;
@property (nonatomic, retain) IBOutlet UILabel *scoreLast;
@property (nonatomic, retain) IBOutlet UILabel *scoreHighest;
@property (nonatomic, retain) IBOutlet UIButton *startBtn;
@end

