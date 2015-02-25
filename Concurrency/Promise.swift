//
//  Promise.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 24/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import Foundation



/**
Promise is an object which can be completed with a value or failed
with an error.
*/
public class Promise<T> {
    
    
    
    // MARK: - Initialization
    
    
    
    public init() {
        self.future = Future<T>()
    }
    
    
    internal init(future: Future<T>) {
        self.future = future
    }
    
    
    
    // MARK: - Public interface
    
    

    /// Future containing the value of this promise.
    internal(set) public var future: Future<T>
    
    
    /// Returns whether the promise has already been completed with a value or an error.
    public var isCompleted: Bool {
        return self.future.isCompleted
    }
    
    
    /**
    Completes the promise with either an error or a value.
    
    :param: result Either the value or the error to complete the promise with.
    
    :returns: self
    */
    public func complete(result: Result<T>) -> Promise<T> {
        if self.tryComplete(result) {
            return self
        } else {
            return throw(IllegalStateException("Promise already completed."))
        }
    }
    
    
    /**
    Tries to complete the promise with either a value or an error.
    
    :param: value Either the value or the error to complete the promise with.
    
    :returns: If the promise has already been completed returns `false`, or `true` otherwise.
    */
    public func tryComplete(value: Result<T>) -> Bool {
        return self.future.tryComplete(value)
    }
    
    
    /**
    Completes this promise with the specified future, once that future is completed.
    
    :param: other The future.
    
    :returns: This promise.
    */
    public final func completeWith(other: Future<T>) -> Promise<T> {
        other.onComplete({
            self.complete($0)
        })
        return self
    }
    
    
    /**
    Attempts to complete this promise with the specified future, once that future is completed.
    
    :param: other The future.
    
    :returns: This promise.
    */
    public final func tryCompleteWith(other: Future<T>) -> Promise<T> {
        other.onComplete({
            self.tryComplete($0)
        })
        return self
    }

}



/**
An already completed Future is given its result at creation.

Useful in Future-composition when a value to contribute is already available.
*/
private final class KeptPromise<T>: Promise<T> {
    
    init(_ suppliedValue: Result<T>) {
        super.init(future: CompletedFuture(suppliedValue))
    }
    
}



