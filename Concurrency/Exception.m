//
//  Exception.m
//  Concurrency
//
//  Created by Peter Zhivkov on 24/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//


#include "Exception.h"



void exc_catch(void (^tryBlock)(void), void (^catchBlock)(NSException *))
{
    @try {
        tryBlock();
    } @catch (NSException *e) {
        catchBlock(e);
    }
}


void exc_throw(NSException *e) {
    @throw e;
}