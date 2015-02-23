//
//  Memory.m
//  Concurrency
//
//  Created by Peter Zhivkov on 22/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "Memory.h"



release_f mem_free_func()
{
    return &free;
}


release_f mem_release_func()
{
    return (release_f)&CFBridgingRelease;
}
