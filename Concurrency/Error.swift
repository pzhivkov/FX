//
//  Error.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 24/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//



public enum Error: ErrorType, CustomStringConvertible, CustomDebugStringConvertible {
    
    case IllegalState(String)
    
    case NoSuchElement(String)
    
    case Timeout(String)
    
    case UnsupportedOperation(String)
    
    
    
    // MARK: - CustomStringConvertible
    
    
    
    public var description: String {
        switch self {
        case let .IllegalState(message):
            return "Error.IllegalState(\"\(message)\")"
        case let .NoSuchElement(message):
            return "Error.NoSuchElement(\"\(message)\")"
        case let .Timeout(message):
            return "Error.Timeout(\"\(message)\")"
        case let .UnsupportedOperation(message):
            return "Error.UnsupportedOperation(\"\(message)\")"
        }
    }
    
    
    
    // MARK: - CustomDebugStringConvertible
    
    
    
    public var debugDescription: String {
        return description
    }
}
