//
//  Exception.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 24/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import Foundation



public class Exception: NSException, Error {
    
    public init(_ desc: String) {
        super.init(name: desc, reason: nil, userInfo: nil)
    }
    
    public override init(name aName: String, reason aReason: String? = nil, userInfo aUserInfo: [NSObject : AnyObject]? = nil) {
        super.init(name: aName, reason: aReason, userInfo: aUserInfo)
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}



public func throw(e: Exception) {
    exc_throw(e)
}

public func throw<A>(e: Exception) -> A {
    exc_throw(e)
    fatalError()
}


public func try<A>(block: () -> A)(catch: Exception -> A) -> A {
    var retValue: A!
    exc_catch({ retValue = block() }, { retValue = catch($0 as! Exception) })
    return retValue!
}


public func try<A>(block: () -> A)(catch: Exception -> ()) -> A? {
    var retValue: A?
    exc_catch({ retValue = block() }, { catch($0 as! Exception) })
    return retValue
}


public func try<A>(block: () -> A) -> Result<A> {
    return try({
        Result.success(block())
    })(catch: {
        Result.Failure($0)
    })
}


public func onException<A, B>(block: () -> A, what: () -> B) -> A {
    return try(block)(catch: { e in
        let b: B = what()
        return throw(e)
    })
}


public func try<A, B>(block: () -> A)(finally: () -> B) -> A {
    let r = onException(block, finally)
    let b = finally()
    return r
}



class PrintableError: Error {
    var description: String
    
    init(_ desc: String) {
        self.description = desc
    }
}


class IllegalStateException: Exception {}

class NoSuchElementException: Exception {}

class TimeoutException: Exception {}




