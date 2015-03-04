//
//  ExecutionContext.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 23/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import Dispatch



public protocol Runnable {
    func run() throws
}


public class DefaultRunnable: Runnable {
 
    
    private let body: () throws -> ()
    
    
    public init(body: () throws -> ()) {
        self.body = body
    }
    
    
    public func run() throws {
        try self.body()
    }
    
}



/**
An `ExecutionContext` can execute program logic asynchronously, 
typically but not necessarily on a dispatch queue.
*/
public protocol ExecutionContext {
    
    /**
    Runs a block of code on this execution context.
    
    - parameter runnable: the task to execute
    */
    func execute(runnable: Runnable) throws

    
    /**
    Reports that an asynchronous computation failed.
    
    - parameter cause: the cause of the failure
    */
    func reportFailure(cause: ErrorType)
    
    
    /**
    Prepares for the execution of a task. Returns the prepared execution context.
    
    `prepare` should be called at the site where an `ExecutionContext` is received (for
    example, through an implicit method parameter). The returned execution context may
    then be used to execute tasks. The role of `prepare` is to save any context relevant
    to an execution's ''call site'', so that this context may be restored at the
    ''execution site''. (These are often different: for example, execution may be
    suspended through a `Promise`'s future until the `Promise` is completed, which may
    be done in another thread, on another stack.)
    
    Note: a valid implementation of `prepare` is one that simply returns `self`.
    
    - returns: the prepared execution context
    */
    func prepare() -> ExecutionContext
}



// MARK: -

final class ExecutionContextImpl: ExecutionContext {
    
    private var label: String! = nil
    private var queue = dispatch_queue_t()
    
    
    
    private final class SyncBlockContext: BlockContext {
        
        private let queue: dispatch_queue_t
        
        
        init(queue: dispatch_queue_t) {
            self.queue = queue
        }
        
        
        final override func blockOn<T>(thunk: () throws -> T)(_ permission: CanAwait) throws -> T {
            var result: Try<T>!
            dispatch_sync(self.queue, {
                result = Try(thunk)
            })
            return try result.get()
        }
    }
    
    
    
    // MARK: - Initialize
    
    
    
    init() {
        let uniqueid = Unmanaged<AnyObject>.passUnretained(self).toOpaque()
        self.label = "com.pzhivkov.concurrency.queue\(uniqueid)"
        
        // Create a concurrent queue.
        //
        self.queue = dispatch_queue_create(
            UnsafePointer<Int8>(Unmanaged<AnyObject>.passUnretained(self.label).toOpaque()),
            DISPATCH_QUEUE_CONCURRENT
        )
        
        // Create a block context for the queue.
        // We can use synchronous dispatch here since the queue is concurrent, and there is
        // no danger of deadlock.
        let blockContext = SyncBlockContext(queue: self.queue)
        BlockContext.queueLocalContext.set(blockContext, queue: self.queue)
    }
    
    
    
    // MARK: - ExecutionContext protocol
    
    
    
    final func execute(runnable: Runnable) throws {
        dispatch_async(self.queue, {
            Try { try runnable.run() }
        })
    }
    
    
    final func reportFailure(cause: ErrorType) {
        print(String(cause))
    }
    
    
    final func prepare() -> ExecutionContext {
        return self
    }
    
}



public let defaultExecutionContext: ExecutionContext = ExecutionContextImpl()

