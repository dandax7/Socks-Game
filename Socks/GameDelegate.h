//
//  GameDelegate.h
//  Socks
//
//  Created by Dan Akselrod on 7/11/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GameDelegate <NSObject>

- (void) sockLost;
- (int) socksMatched;
@end
