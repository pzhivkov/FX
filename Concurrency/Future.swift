//
//  Future.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 24/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import Darwin
import Dispatch



public class Future<T>: Awaitable {
    
    
    private let internalExecutionContext = defaultExecutionContext
    
    
    
    // MARK: - Initialization
    
    
    
    internal init() {
        // The future is incomplete and has no callbacks.
        self.state.update(nil, newValue: LinkedNode<CallbackRunnable<T>>())
    }
    
    
    public convenience init(executionContext: ExecutionContext = defaultExecutionContext, _ body: () -> T) {
        self.init()
        let runnable = PromiseCompletingRunnable(future: self, body: body)
        executionContext.prepare().execute(runnable)
    }
 
    
    
    // MARK: - Callbacks
    
    
    
    /**
    When this future is completed successfully (i.e., with a value),
    apply the provided callback to the value.
    
    If the future has already been completed with a value,
    this will either be applied immediately or be scheduled asynchronously.
    */
    public func onSuccess(body: T -> Void, executionContext: ExecutionContext) {
        onComplete({
            switch $0 {
            case let .Success(v):
                return body(v.unbox)
            default:
                break
            }
        }, executionContext: executionContext)
    }
    
    public final func onSuccess(body: T -> Void) {
        return self.onSuccess(body, executionContext: defaultExecutionContext)
    }
    
    
    /**
    When this future is completed with a failure (i.e., with an error),
    apply the provided callback to the error.

    If the future has already been completed with a failure,
    this will either be applied immediately or be scheduled asynchronously.

    Will not be called in case that the future is completed with a value.
    */
    public func onFailure(body: Error -> Void, executionContext: ExecutionContext) {
        onComplete({
            switch $0 {
            case let .Failure(t):
                return body(t)
            default:
                break
            }
        }, executionContext: executionContext)
    }
    
    public final func onFailure(body: Error -> Void) {
        return self.onFailure(body, executionContext: defaultExecutionContext)
    }
    
    
    /**
    When this future is completed, either through an error, or a value,
    apply the provided function.
    
    If the future has already been completed,
    this will either be applied immediately or be scheduled asynchronously.
    */
    public func onComplete(body: Result<T> -> Void, executionContext: ExecutionContext) {
        let preparedEC = executionContext.prepare()
        let runnable = CallbackRunnable<T>(executionContext: preparedEC, onComplete: body)
        self.dispatchOrAddCallback(runnable)
    }
    
    public final func onComplete(body: Result<T> -> Void) {
        self.onComplete(body, executionContext: defaultExecutionContext)
    }

    
    
    // MARK: - Miscellaneous
    
    
    
    /**
    Returns whether the future has already been completed with a value or an error.
    
    `true` if the future is already completed, `false` otherwise
    */
    public var isCompleted: Bool {
        switch self.state.get() {
        case is Result<T>:
            return true
            
        case is Future<T>:
            return self.compressedRoot.isCompleted
            
        default:
            return false
        }
    }
    
    
    /**
    The value of this `Future`.

    If the future is not completed, the returned value will be `nil`.
    If the future is completed, the value will be `Result.Success(t)`
    if it contains a valid result, or `Result.Failure(error)` if it contains
    an error.
    */
    public var value: Result<T>? {
        switch self.state.get() {
        case let c as Result<T>:
            return c
            
        case is Future<T>:
            return self.compressedRoot.value
            
        default:
            return nil
        }
    }
    
    
    
    // MARK: - Projections
    
    
    
    /**
    Returns a failed projection of this future.
    
    The failed projection is a future holding a value of type `Error`.

    It is completed with a value which is the error of the original future
    in case the original future is failed.
    
    It is failed with a `NoSuchElementError` if the original future is completed successfully.
    
    Blocking on this future returns a value if the original future is completed with an exception
    and throws a corresponding exception if the original future fails.
    */
    public var failed: Future<Error> {
        let p = Promise<Error>()
        self.onComplete({
            switch $0 {
            case let .Failure(t):
                p.success(t)
            case let .Success(v):
                p.failure(NoSuchElementException("Future.failed not completed with an error."))
            }
        }, executionContext: internalExecutionContext)
        return p.future
    }
    
    
    
    // MARK: - Awaitable protocol
    
    
    /**
    Try waiting for this promise to be completed.
    */
    internal final func tryAwait(atMost: Duration) -> Bool {
        if !self.isCompleted {
            let l = CompletionLatch()
            self.onComplete({ _ in
                l.apply()
            }, executionContext: internalExecutionContext)
            l.acquire(atMost)
            
            return self.isCompleted
        } else {
            return true
        }
    }
    
    
    public func ready(atMost: Duration)(_ permit: CanAwait) -> Self {
        if self.tryAwait(atMost) {
            return self
        } else {
            return throw(TimeoutException("Future timed out after \(atMost)."))
        }
    }
    
    
    public func result(atMost: Duration)(_ permit: CanAwait) -> T {
        // ready() throws TimeoutException if timeout so value! is safe here.
        return self.ready(atMost)(permit).value!.get()
    }
    
    
    
    // MARK: - Default implementation
    
    
    
    /**
    Default future implementation
    */
    
    private var state = AtomicObject<AnyObject>()
    
    
    /**
    Get the root future for this future, compressing the link chain to that
    future if necessary.
    
    For futures that are not linked, the result of getting
    `compressedRoot` will be the future itself. However for linked futures,
    this method will traverse each link until it locates the root future at
    the base of the link chain.
    
    As a side effect of calling this method, the link from this future back
    to the root future will be updated ("compressed") to point directly to
    the root future. This allows intermediate futures in the link chain to
    be released. Also, subsequent calls to this method should be
    faster as the link chain will be shorter.
    */
    private var compressedRoot: Future<T> {
        switch self.state.get() {
        case let linked as Future<T>:
            let target = linked.root
            if linked === target {
                return target
            } else if self.state.update(linked, newValue: target) {
                return target
            } else {
                return self.compressedRoot
            }
            
        default:
            return self
        }
    }
    
    
    /**
    Get the future at the root of the chain of linked futures. Used by `compressedRoot`.
    The `compressedRoot` getter should be called instead of this getter, as it is important
    to compress the link chain whenever possible.
    */
    private var root: Future<T> {
        switch self.state.get() {
        case let linked as Future<T>:
            return linked.root
            
        default:
            return self
        }
    }
    
    
    /**
    Tries to complete the promise with either a value or an error.
    
    :param: value Either the value or the error to complete the promise with.
    
    :returns: If the promise has already been completed returns `false`, or `true` otherwise.
    */
    internal func tryComplete(value: Result<T>) -> Bool {
        switch self.tryCompleteAndGetListeners(value) {
        case nil:
            return false
            
        case let listeners where listeners?.data == nil:
            return true
            
        case let listeners:
            for var node = listeners; node?.data != nil; node = node?.next {
                let callbackRunnable: CallbackRunnable<T>? = node?.data
                callbackRunnable?.execute(value)
            }
            return true
        }
    }
    
    
    /**
    Called by `tryComplete` to store the resolved value and get the list of
    listeners, or `nil` if it is already completed.
    */
    private func tryCompleteAndGetListeners(value: Result<T>) -> LinkedNode<CallbackRunnable<T>>? {
        switch self.state.get() {
        case let listeners as LinkedNode<CallbackRunnable<T>>:
            if self.state.update(listeners, newValue: Box(value)) {
                return listeners
            } else {
                return self.tryCompleteAndGetListeners(value)
            }
            
        case is Future<T>:
            return self.compressedRoot.tryCompleteAndGetListeners(value)
            
        default:
            return nil
        }
    }

    
    /**
    Tries to add the callback, if already completed, it dispatches the callback to be executed.
    Used by `onComplete()` to add callbacks to a future and by `link()` to transfer callbacks
    to the root future when linking two futures togehter.
    */
    private func dispatchOrAddCallback(runnable: CallbackRunnable<T>) {
        switch self.state.get() {
        case let r as Result<T>:
            runnable.execute(r)
            
        case is Future<T>:
            self.compressedRoot.dispatchOrAddCallback(runnable)
            
        case let listeners as LinkedNode<CallbackRunnable<T>>:
            let newListeners = LinkedNode(runnable)
            newListeners.next = listeners
            if self.state.update(listeners, newValue: newListeners) {
                return
            } else {
                self.dispatchOrAddCallback(runnable)
            }
            
        default:
            return
        }
    }
    
    
    /**
    Link this future to the root of another future using `link()`. Should only be
    be called by Future.flatMap.
    */
    internal final func linkRootOf(target: Future<T>) {
        link(target.compressedRoot)
    }
    
    
    /**
    Link this future to another future so that both futures share the same
    externally-visible state. Depending on the current state of this future, this
    may involve different things. For example, any onComplete listeners will need
    to be transferred.
    
    If this future's promise is already completed, then the same effect as linking -
    sharing the same completed value - is achieved by simply sending this
    future's value to the target future.
    */
    private func link(target: Future<T>) -> Result<()> {
        if self !== target {
            switch self.state.get() {
            case let r as Result<T>:
                if !target.tryComplete(r) {
                    // Currently linking is done from Future.flatMap, which should ensure only
                    // one promise can be completed. Therefore this situation is unexpected.
                    return Result.failure(IllegalStateException("Cannot link completed promises together"))
                }
                
            case is Future<T>:
                self.compressedRoot.link(target)
                
            case let listeners as LinkedNode<CallbackRunnable<T>>:
                if self.state.update(listeners, newValue: target) {
                    for var node: LinkedNode<CallbackRunnable<T>>? = listeners; node?.data != nil; node = node?.next {
                        if let callbackRunnable = node?.data {
                            target.dispatchOrAddCallback(callbackRunnable)
                        }
                    }
                } else {
                    self.link(target)
                }
            default:
                break
            }
        }
        return Result.success()
    }

}



// MARK: -

/**
An already completed Future is given its result at creation.

Useful in Future-composition when a value to contribute is already available.
*/
internal final class CompletedFuture<T>: Future<T> {
    
    
    private var completedValue: Result<T>

    
    init(_ value: Result<T>) {
        self.completedValue = value
        super.init()
    }
    
    
    override var value: Result<T>? {
        return self.completedValue
    }
    
    override var isCompleted: Bool {
        return true
    }
    
    override func tryComplete(value: Result<T>) -> Bool {
        return false
    }
    
    override func onComplete(body: Result<T> -> Void, executionContext: ExecutionContext = defaultExecutionContext) {
        CallbackRunnable(executionContext: executionContext.prepare(), onComplete: body).execute(completedValue)
    }
    
    override func ready(atMost: Duration)(_ permit: CanAwait) -> Self {
        return self
    }
    
    override func result(atMost: Duration)(_ permit: CanAwait) -> T {
        return self.completedValue.get()
    }
}



// MARK: -

/**
A marker indicating that a `Runnable` provided to an `ExecutionContext`
wraps a callback provided to `Future.onComplete`.
All callbacks provided to a `Future` end up going through `onComplete`, so this allows an
`ExecutionContext` to special-case callbacks that were executed by `Future` if desired.
*/
protocol OnCompleteRunnable: Runnable {}



/**
Precondition: `executor` is prepared, i.e., `executor` has been returned from invocation of `prepare` on some other `ExecutionContext`.
*/
private final class CallbackRunnable<T>: OnCompleteRunnable {
    
    var value: Result<T>? = nil
    
    private let executionContext: ExecutionContext
    
    private let onComplete: Result<T> -> Void
    
    
    init(executionContext: ExecutionContext, onComplete: Result<T> -> Void) {
        self.executionContext = executionContext
        self.onComplete = onComplete
    }
    
    func run() {
        
        precondition(value != nil, "Must set value to non-nil before running!")

        try({
            self.onComplete(self.value!)
        })(catch: {
            self.executionContext.reportFailure($0)
        }) as Void
    }
    
    func execute(value: Result<T>) {
        
        precondition(self.value == nil, "Can't complete a promise twice.")
        
        self.value = value
        
        // Note that we cannot prepare the ExecutionContext at this point, since we might
        // already be running on a different thread!
        
        try({
            self.executionContext.execute(self)
        })(catch: {
            self.executionContext.reportFailure($0)
        }) as Void
    }
}



// MARK: -

class PromiseCompletingRunnable<T>: Runnable {
    
    var promise: Promise<T>
    
    private var runnableBody: () -> () = {}
    
    
    init(future: Future<T>, body: () -> T) {
        
        self.promise = Promise(future: future)
        
        self.runnableBody = {
            
            let result: Result<T> = try({
                return Result.success(body())
            })(catch: {
                return Result.failure($0)
            })
            
            self.promise.complete(result)
        }
    }
    
    func run() {
        return self.runnableBody()
    }
}



// MARK: -

private final class CompletionLatch {
    
    private var sem: dispatch_semaphore_t!
    
    
    init!() {
        self.sem = dispatch_semaphore_create(0)
        if self.sem == nil {
            return nil
        }
    }
    
    func apply() {
        dispatch_semaphore_signal(self.sem)
    }
    
    func acquire(wait: Duration) -> Bool {
        return dispatch_semaphore_wait(self.sem, wait) == 0
    }
    
}



// MARK: -

private final class LinkedNode<T> {
    
    var data: T?
    
    var next: LinkedNode<T>?
    
    
    init() {} // Empty list.
    
    init(_ data: T) {
        self.data = data
    }
}


