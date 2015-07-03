//
//  MutableMatrix
//  Socks
//
//  Created by Dan Akselrod on 5/19/15.
//  Copyright (c) 2015 dantap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

@interface SockMatrix : NSObject
{
    NSMutableArray *store;
}

+ (instancetype)matrixWithShapes:(int)s Patterns:(int)p;

- (instancetype)initWithShapes:(int)s Patterns:(int)p;

- (void)       insertSock: (SKTexture*) obj
                    Shape: (int)r
                  Pattern: (int)c;

- (SKTexture*) getSockShape: (int)r
                    Pattern: (int)c;

@property (nonatomic, readonly) int shapes;
@property (nonatomic, readonly) int patterns;

@end


