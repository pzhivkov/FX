//
//  Memory.h
//  Concurrency
//
//  Created by Peter Zhivkov on 22/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

#ifndef Reactive_MemRelease_h
#define Reactive_MemRelease_h



typedef void (*release_f)(void *);


release_f mem_free_func();

release_f mem_release_func();


#endif
