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
    
    
    /**
    Creates a promise object which can be completed with a value.
    
    :returns: The newly created `Promise` object.
    */
    public init() {
        self.future = Future<T>()
    }
    
    
    internal init(future: Future<T>) {
        self.future = future
    }
    
    
    
    // MARK: - Public interface
    
    

    /// Future containing the value of this promise.
    internal(set) public var future: Future<T>
    
    
    /** 
    Returns whether the promise has already been completed with a value or an error.
    
    Note: Using this property may result in non-deterministic concurrent programs.
    */
    public var isCompleted: Bool {
        return self.future.isCompleted
    }
    
    
    /**
    Completes the promise with either an error or a value.
    
    If the promise has already been fulfilled, failed or has timed out,
    calling this method will throw an IllegalStateException.
    
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
    
    Note: Using this method may result in non-deterministic concurrent programs.
    
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
    
    
    /**
    Completes the promise with a value.
    
    If the promise has already been fulfilled, failed or has timed out,
    calling this method will throw an IllegalStateException.
    
    :param: value The value to complete the promise with.
    
    :returns: The promise.
    */
    public func success(value: T) -> Promise<T> {
        return self.complete(Result.success(value))
    }
    
    
    /**
    Tries to complete the promise with a value.
    
    Note: Using this method may result in non-deterministic concurrent programs.
    
    :param: value A value.
    
    :returns: If the promise has already been completed returns `false`, or `true` otherwise.
    */
    public func trySuccess(value: T) -> Bool {
        return self.tryComplete(Result.success(value))
    }
    
    
    /**
    Completes the promise with an error.
    
    If the promise has already been fulfilled, failed or has timed out,
    calling this method will throw an IllegalStateException.
    
    :param: cause The error to complete the promise with.
    
    :returns: The promise.
    */
    public func failure(cause: Error) -> Promise<T> {
        return self.complete(Result.failure(cause))
    }
    
    
    /**
    Tries to complete the promise with an error.
    
    Note: Using this method may result in non-deterministic concurrent programs.
    
    :param: cause An error.
    
    :returns: If the promise has already been completed returns `false`, or `true` otherwise.
    */
    public func tryFailure(cause: Error) -> Bool {
        return self.tryComplete(Result.failure(cause))
    }

}



// MARK: -



public extension Promise {
    
    /**
    Creates an already completed Promise with the specified error.
    
    :param: error The error.
    
    :returns: The newly created `Promise` object.
    */
    public class func failed<T>(error: Error) -> Promise<T> {
        return Promise.fromResult(Result.failure(error))
    }
    
    
    /**
    Creates an already completed Promise with the specified result.
    
    :param: result The result.
    
    :returns: The newly created `Promise` object.
    */
    public class func successful<T>(result: T) -> Promise<T> {
        return Promise.fromResult(Result.success(result))
    }
    
    
    /**
    Creates an already completed Promise with the specified result or error.
    
    :param: result The result or error.
    
    :returns: The newly created `Promise` object.
    */
    public class func fromResult<T>(result: Result<T>) -> Promise<T> {
        return KeptPromise(result)
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



