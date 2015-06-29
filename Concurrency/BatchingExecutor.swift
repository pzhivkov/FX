//
//  BatchingExecutor.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 03/03/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//



/**
An override of ExecutionContext
which groups multiple nested `Runnable.run()` calls
into a single Runnable passed to the original
ExecutionContext. This can be a useful optimization
because it bypasses the original context's task
queue and keeps related (nested) code on a single
thread which may improve CPU affinity. However,
if tasks passed to the ExecutionContext are blocking
or expensive, this optimization can prevent work-stealing
and make performance worse. Also, some ExecutionContext
may be fast enough natively that this optimization just
adds overhead.
A batching executor can create deadlocks if code does
not use `blocking` when it should,
because tasks created within other tasks will block
on the outer task completing.
This executor may run tasks in any order, including LIFO order.
There are no ordering guarantees.

WARNING: The underlying Executor's execute-method must not execute the submitted Runnable
in the calling thread synchronously. It must enqueue/handoff the Runnable.
*/
internal class BatchingExecutor: ExecutionContext {
    
    // Invariant: If "tasksLocal.get() != nil" then we are inside Batch.run(); if it is nil, we are outside.
    private let tasksLocal = ThreadLocal<LinkedList<Runnable>>()
    

    private class Batch: BlockContext, Runnable {
     
        private var parentBlockContext: BlockContext!
        
        private let initial: LinkedList<Runnable>
        
        private let executor: BatchingExecutor
        
        
        init(initial: LinkedList<Runnable>, executor: BatchingExecutor) {
            self.initial = initial
            self.executor = executor
            super.init()
        }
        
        
        /**
        This method runs in the delegate ExecutionContext's thread
        */
        func run() throws {
            precondition(self.executor.tasksLocal.get() == nil)
            
            let prevBlockContext = BlockContext.current
            
            try BlockContext.withBlockContext(self)({ () throws -> Void in
                
                defer {
                    self.executor.tasksLocal.set(nil)
                    self.parentBlockContext = nil
                }
                do {
                    self.parentBlockContext = prevBlockContext
                    
                    var batch = self.initial
                    while let head = batch.data {
                        self.executor.tasksLocal.set(batch.next)
                        do {
                            try head.run()
                        }
                        catch let t {
                            // If one task throws, move the
                            // remaining tasks to another thread
                            // so we can throw the exception
                            // up to the invoking executor.
                            let remaining = self.executor.tasksLocal.get()!
                            self.executor.tasksLocal.set(nil)
                            let batch = Batch(initial: remaining, executor: self.executor)
                            try self.executor.unbatchedExecute(batch)
                            throw t
                        }
                        batch = self.executor.tasksLocal.get()! // Since head.run() can add entries, always do tasksLocal.get here.
                    }
                }
            })
        }
        
        
        private final override func blockOn<T>(thunk: () throws -> T)(_ permission: CanAwait) throws -> T {
             // If we know there will be blocking, we don't want to keep tasks queued up because it could deadlock.
            let tasks = self.executor.tasksLocal.get()
            self.executor.tasksLocal.set(nil)
            if tasks?.data != nil {
                try self.executor.unbatchedExecute(Batch(initial: tasks!, executor: self.executor))
            }
            
            // Now delegate the blocking to the previous BC.
            precondition(self.parentBlockContext != nil)
            return try self.parentBlockContext!.blockOn(thunk)(permission)
        }
        
        private final override func blockOn<T>(thunk: () -> T)(_ permission: CanAwait) -> T {
            return try! blockOn({ () throws -> T in thunk() })(permission)
        }
    }
    
    
    
    // MARK: - Unbatched execution
    
    
    
    func unbatchedExecute(r: Runnable) throws {
        fatalError("This method must be overridden.")
    }

    
    
    // MARK: - ExecutionContext protocol
    
    
    
    func execute(runnable: Runnable) throws {
        if isBatchable(runnable) {
            let nilNode = LinkedList<Runnable>()
            let runNode = LinkedList(runnable)
            runNode.next = nilNode
            
            switch self.tasksLocal.get() {
            case nil:
                // If we aren't in batching mode yet, enqueue batch.
                try self.unbatchedExecute(Batch(initial: runNode, executor: self))
                
            case let some:
                // If we are already in batching mode, add to batch.
                let augmentedList = runNode
                augmentedList.next = some
                self.tasksLocal.set(augmentedList)
            }
        } else {
            // If not batchable, just delegate to underlying.
            try self.unbatchedExecute(runnable)
        }
    }
    
    
    func reportFailure(cause: ErrorType) {
        print(String(cause))
    }
    
    
    func prepare() -> ExecutionContext {
        return self
    }

    

    // MARK: - Batchable
    
    
    
    /**
    Override this to define which runnables will be batched.
    */
    func isBatchable(runnable: Runnable) -> Bool {
        switch runnable {
        case is OnCompleteRunnable:
            return true
        default:
            return false
        }
    }
}
