//
//  Result.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 24/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import class Foundation.NSError



public protocol Error: Printable { }


extension NSError: Error { }




public class Box<T> {
    let unbox: T
    init(_ value: T) { self.unbox = value }
}



public enum Result<T> {
    
    case Success(Box<T>)
    
    case Failure(Error)
    
    
    func flatMap<U>(f: T -> Result<U>) -> Result<U> {
        switch self {
        case let .Success(box):
            return f(box.unbox)
        case let .Failure(error):
            return .Failure(error)
        }
    }
    
    
    func map<U>(f: T -> U) -> Result<U> {
        switch self {
        case let .Success(box):
            return .Success(Box(f(box.unbox)))
        case let .Failure(error):
            return .Failure(error)
        }
    }
}



func map<T, U>(result: Result<T>, f: T -> U) -> Result<U> {
    return result.map(f)
}


@inline(__always) func ??<T>(result: Result<T>, handleError: Error -> T) -> T {
    switch result {
    case let Result.Success(box):
        return box.unbox
    case let Result.Failure(error):
        return handleError(error)
    }
}


func ??<T>(result: Result<T>, @autoclosure defaultValue: () -> T) -> T {
    switch result {
    case let Result.Success(box):
        return box.unbox
    case let Result.Failure(error):
        return defaultValue()
    }
}


func ??<T>(result: Result<T>, @autoclosure defaultValue: () -> T?) -> T? {
    switch result {
    case let Result.Success(box):
        return box.unbox
    case let Result.Failure(error):
        return defaultValue()
    }
}
