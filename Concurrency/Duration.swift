//
//  Duration.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 21/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//


import Dispatch



public typealias Duration = dispatch_time_t


public extension Duration {
    
    public static func forever() -> Duration {
        return DISPATCH_TIME_FOREVER
    }
    
    public static func now() -> Duration {
        return DISPATCH_TIME_NOW
    }
    
    public static func inNano(nanos: Int64) -> Duration {
        return dispatch_walltime(nil, nanos)
    }
}