//
//  Duration.swift
//  FX
//
//  Created by Peter Zhivkov on 21/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//


import Dispatch



public typealias Duration = dispatch_time_t


public extension Duration {
    
    public static var Forever: Duration {
        return DISPATCH_TIME_FOREVER
    }
    
    public static var Zero: Duration {
        return DISPATCH_TIME_NOW
    }
    
    public static func inNanos(nanos: Int64) -> Duration {
        return dispatch_time(DISPATCH_TIME_NOW, nanos)
    }
}



public extension Int {
    
    public var seconds: Duration {
        return Duration.inNanos(Int64(self) * Int64(NSEC_PER_SEC))
    }
    
    public var milliseconds: Duration {
        return Duration.inNanos(Int64(self) * Int64(NSEC_PER_MSEC))
    }
    
    public var microseconds: Duration {
        return Duration.inNanos(Int64(self) * Int64(NSEC_PER_USEC))
    }
}

