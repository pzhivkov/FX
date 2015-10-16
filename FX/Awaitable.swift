//
//  Awaitable.swift
//  FX
//
//  Created by Peter Zhivkov on 21/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//



public class CanAwait {
    private init() {}
}


let awaitPermission = CanAwait()



/**
An object that may eventually be completed with a result value of type `T` which may be
awaited using blocking methods.

The ``Await`` object provides methods that allow accessing the result of an `Awaitable`
by blocking the current thread until the `Awaitable` has been completed or a timeout has
occurred.
*/
public protocol Awaitable {
    
    typealias T
    
    
    /**
    Await the "completed" state of this `Awaitable`.
    
    Note: This method should not be called directly; use `Await.ready` instead.
    
    - parameter atMost:  maximum wait time
    
    - returns: self
    */
    func ready(atMost: Duration)(_ permit: CanAwait) throws -> Self
    
    
    
    /**
    Await and return the result (of type `T`) of this `Awaitable`.
    
    Note: This method should not be called directly; use `Await.result` instead.
    
    - parameter atMost: maximum wait time
    
    - returns: a value of type `T`
    */
    func result(atMost: Duration)(_ permit: CanAwait) throws -> T
    
}



public final class Await {

    private init() {}
    
    
    /**
    Await the "completed" state of an `Awaitable`.
    
    - parameter awaitable: the `Awaitable` to be awaited
    - parameter atMost:    maximum wait time
    
    - returns: the awaitable
    */
    public class func ready<A: Awaitable>(awaitable: A, atMost: Duration) throws -> A {
        return try blocking {
            try awaitable.ready(atMost)(awaitPermission)
        }
    }
    
    /**
    Await and return the result (of type `T`) of an `Awaitable`.
    
    - parameter awaitable: the `Awaitable` to be awaited
    - parameter atMost:    maximum wait time
    
    - returns: the result of the `Awaitable`
    */
    public class func result<A: Awaitable>(awaitable: A, atMost: Duration) throws -> A.T {
        return try blocking {
            try awaitable.result(atMost)(awaitPermission)
        }
    }
}

