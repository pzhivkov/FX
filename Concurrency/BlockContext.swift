//
//  BlockContext.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 21/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//




/**
A context to be notified when a thread is about to block.
*/
public class BlockContext {
    
    /**
    Used internally by the framework;
    Designates (and eventually executes) a thunk which potentially blocks the calling `Thread`.
    
    Note: BlockContext msut be subclassed, and this method must be always overridden.
    
    - parameter thunk: the blocking thunk
    
    - returns: the thunk's return value
    */
    public func blockOn<T>(thunk: () throws -> T)(_ permission: CanAwait) throws -> T {
        fatalError("This method must be overridden.")
    }
    
    
    
    // MARK: - Class variables and methods
    
    
    
    private final class DefaultBlockContext: BlockContext {
        private final override func blockOn<T>(thunk: () throws -> T)(_ permission: CanAwait) throws -> T {
            return try thunk()
        }
    }
    
    private static let defaultBlockContext = DefaultBlockContext()

    private static let threadLocalContext = ThreadLocal<BlockContext>()
    
    public static let queueLocalContext = QueueLocal<BlockContext>()
    
    
    /// Obtain the current thread's current `BlockContext`
    public static var current: BlockContext {
        return threadLocalContext.get()
            ?? queueLocalContext.get()
            ?? defaultBlockContext
    }
    
    
    /**
    Pushes a current `BlockContext` while executing `body`.
    
    - parameter blockContext: a context
    
    - returns: return value from the `body`
    */
    public class func withBlockContext<T>(blockContext: BlockContext)(_ body: () throws -> T) throws -> T {
        let old = BlockContext.threadLocalContext.get() // Can be nil.
        BlockContext.threadLocalContext.set(blockContext)
        defer {
            BlockContext.threadLocalContext.set(old)
        }
        
        return try body()
    }
    
}


/**
Used to designate a piece of code which potentially blocks, allowing the current `BlockContext` to adjust
the runtime's behavior.
Properly marking blocking code may improve performance or avoid deadlocks.

Blocking on an `Awaitable` should be done using `Await.result` instead of `blocking`.

- parameter body: A piece of code which contains potentially blocking or long running calls.

- returns: The body's return value.
*/
public func blocking<T>(body: () throws -> T) throws -> T {
    return try BlockContext.current.blockOn(body)(awaitPermission)
}


