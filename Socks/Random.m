//
//  Random.m
//  Socks
//
//  Created by Dan Akselrod on 4/20/14.
//  Copyright (c) 2014 dantap. All rights reserved.
//

#include <stdlib.h>

double arc4random_uniform_float(double min, double max, double resolution)
{
    double range = max - min;
    u_int32_t int_range = range / resolution;
    u_int32_t rnd = arc4random_uniform(int_range);
    double rnd_d = rnd * resolution;
    rnd_d += min;
    return rnd_d;
}

BOOL arc4random_boolean(float chance_true)
{
    if (chance_true > 1) return TRUE;
    if (chance_true <= 0) return FALSE;
    
    u_int32_t rnd = arc4random_uniform(1000);
    return rnd < chance_true * 1000;
}