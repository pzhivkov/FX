//
//  Result.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 24/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import class Foundation.NSError



public protocol Error: Printable {}


extension NSError: Error {}




public class Box<T> {
    let unbox: T
    init(_ value: T) { self.unbox = value }
}



public enum Result<T> {
    
    case Success(Box<T>)
    
    case Failure(Error)
    
    
    
    public static func success(value: T) -> Result<T> {
        return .Success(Box(value))
    }
    
    
    public static func failure(err: Error) -> Result<T> {
        return .Failure(err)
    }
    
    
    
    public func flatMap<U>(@noescape f: T -> Result<U>) -> Result<U> {
        switch self {
        case let .Success(box):
            return f(box.unbox)
        case let .Failure(error):
            return .Failure(error)
        }
    }
    
    
    public func map<U>(@noescape f: T -> U) -> Result<U> {
        switch self {
        case let .Success(box):
            return .Success(Box(f(box.unbox)))
        case let .Failure(error):
            return .Failure(error)
        }
    }
}



public func map<T, U>(result: Result<T>, @noescape f: T -> U) -> Result<U> {
    return result.map(f)
}


public func ??<T>(result: Result<T>, @noescape handleError: Error -> T) -> T {
    switch result {
    case let Result.Success(box):
        return box.unbox
    case let Result.Failure(error):
        return handleError(error)
    }
}


public func ??<T>(result: Result<T>, @autoclosure defaultValue: () -> T) -> T {
    switch result {
    case let Result.Success(box):
        return box.unbox
    case let Result.Failure(error):
        return defaultValue()
    }
}


public func ??<T>(result: Result<T>, @autoclosure defaultValue: () -> T?) -> T? {
    switch result {
    case let Result.Success(box):
        return box.unbox
    case let Result.Failure(error):
        return defaultValue()
    }
}
