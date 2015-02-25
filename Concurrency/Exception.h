//
//  Exception.h
//  Concurrency
//
//  Created by Peter Zhivkov on 24/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

#ifndef Concurrency_Exception_h
#define Concurrency_Exception_h


@class NSException;


void exc_catch(void (^tryBlock)(void), void (^catchBlock)(NSException *));


#endif
