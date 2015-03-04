//
//  Error.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 24/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//



public enum Error: ErrorType {
    
    case IllegalState(String)
    
    case NoSuchElement(String)
 
    case Timeout(String)
    
    case UnsupportedOperation(String)
}
