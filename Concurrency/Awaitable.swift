//
//  Awaitable.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 21/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//



public final class CanAwait {
    private init() {}
}


let awaitPermission = CanAwait()




public protocol Awaitable {
    
    typealias T
    
    func ready(atMost: Duration)(_ permit: CanAwait) -> Awaitable
    
    func result(atMost: Duration)(_ permit: CanAwait) -> T
    
}



public final class Await {

    private init() {}
    
    
    
    public class func ready<A: Awaitable>(awaitable: A, atMost: Duration) -> A {
        return blocking {
            awaitable.ready(atMost)(awaitPermission) as! A
        }
    }
    
    
    public class func result<A: Awaitable>(awaitable: A, atMost: Duration) -> A.T {
        return blocking {
            awaitable.result(atMost)(awaitPermission)
        }
    }
}
