//
//  Exception.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 24/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import class Foundation.NSException



public typealias Exception = Error


extension NSException: Exception {}



public func throw(e: Exception) {
    fatalError(e.description)
}

public func throw<A>(e: Exception) -> A {
    fatalError(e.description)
}


public func try<A>(block: () -> A)(catch: Exception -> A) -> A {
    var retValue: A!
    exc_catch({ retValue = block() }, { retValue = catch($0) })
    return retValue!
}


public func try<A>(block: () -> A)(catch: Exception -> ()) -> A? {
    var retValue: A?
    exc_catch({ retValue = block() }, { catch($0) })
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


class IllegalStateException: PrintableError, Exception {}

class NoSuchElementException: PrintableError, Exception {}

class TimeoutException: PrintableError, Exception {}




