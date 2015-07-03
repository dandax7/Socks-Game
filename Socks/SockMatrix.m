//
//  MutableMatrix
//  Socks
//
//  Created by Dan Akselrod on 5/19/15.
//  Copyright (c) 2015 dantap. All rights reserved.
//

#import "SockMatrix.h"

@implementation SockMatrix


//
//        0 1 2 3  Shape
//
// P  0   0 1 2 3
// a  1   4 5 6 7
// t  2   8 9 10 ...
// t  3
//
+ (instancetype)matrixWithShapes:(int)s Patterns:(int)p
{
    return [[SockMatrix alloc] initWithShapes: s Patterns:p];
}

- (int) indexShape: (int)s Pattern:(int)p
{
    if (s >= _shapes)
    {
        [NSException raise: @"Out of bounds"
                    format: @"Asking for shape %d from max %d", s, _shapes];
    }
    if (p >= _patterns)
    {
        [NSException raise: @"Out of bounds"
                    format: @"Asking for pattern %d from max %d", p, _patterns];
    }

    return _patterns * s + p;
}

- (instancetype)initWithShapes:(int)s Patterns:(int)p
{
    if (self = [super init])
    {
        _patterns = p;
        _shapes = s;
        store = [NSMutableArray arrayWithCapacity:s * p];
        for (int i = 0; i < s * p; ++i)
             [store addObject: [NSObject new]];
    }
    return self;
}

- (void)       insertSock: (SKTexture*) obj
                    Shape: (int)s
                  Pattern: (int)p
{
    [store insertObject: obj atIndex: [self indexShape:s Pattern:p]];
}

- (SKTexture*) getSockShape:(int)s Pattern:(int)p
{
    return [store objectAtIndex: [self indexShape:s Pattern:p]];
}


@end
