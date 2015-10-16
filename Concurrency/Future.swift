//
//  Future.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 24/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import Dispatch



public class Future<T>: Awaitable {
    
    
    /**
    The executor within the lexical scope of the Future. Note that this will
    (modulo bugs) _never_ execute a callback other than those below in this same file.
    
    See the documentation on `InternalCallbackExecutor` for more details.
    */
    private let internalExecutionContext = InternalCallbackExecutor()
    
    
    
    // MARK: - Initialization
    
    
    
    internal init() {
        // The future is incomplete and has no callbacks.
        self.state.update(nil, newValue: LinkedList<CallbackRunnable<T>>())
    }
    
    
    public convenience init(executionContext: ExecutionContext = defaultExecutionContext, _ body: () throws -> T) {
        self.init()
        let runnable = PromiseCompletingRunnable(future: self, body: body)
        try! executionContext.prepare().execute(runnable)
    }
    
    
    
    // MARK: - Callbacks
    
    
    
    /**
    When this future is completed successfully (i.e., with a value),
    apply the provided callback to the value.
    
    If the future has already been completed with a value,
    this will either be applied immediately or be scheduled asynchronously.
    */
    public func onSuccess(executionContext: ExecutionContext = defaultExecutionContext)(_ body: T throws -> Void) {
        onComplete(executionContext)({
            switch $0 {
            case let .Success(v):
                return try body(v)
            default:
                break
            }
        })
    }
    
    public final func onSuccess(body: T throws -> Void) {
        return self.onSuccess()(body)
    }
    
    
    /**
    When this future is completed with a failure (i.e., with an error),
    apply the provided callback to the error.

    If the future has already been completed with a failure,
    this will either be applied immediately or be scheduled asynchronously.

    Will not be called in case that the future is completed with a value.
    */
    public func onFailure(executionContext: ExecutionContext = defaultExecutionContext)(_ body: ErrorType throws -> Void) {
        onComplete(executionContext)({
            switch $0 {
            case let .Failure(t):
                return try body(t)
            default:
                break
            }
        })
    }
    
    public final func onFailure(body: ErrorType throws -> Void) {
        return self.onFailure()(body)
    }
    
    
    /**
    When this future is completed, either through an error, or a value,
    apply the provided function.
    
    If the future has already been completed,
    this will either be applied immediately or be scheduled asynchronously.
    */
    public func onComplete(executionContext: ExecutionContext = defaultExecutionContext)(_ body: Try<T> throws -> Void) {
        let preparedEC = executionContext.prepare()
        let runnable = CallbackRunnable<T>(executionContext: preparedEC, onComplete: body)
        self.dispatchOrAddCallback(runnable)
    }
    
    public final func onComplete(body: Try<T> throws -> Void) {
        self.onComplete()(body)
    }

    
    
    // MARK: - Miscellaneous
    
    
    
    /**
    Returns whether the future has already been completed with a value or an error.
    
    `true` if the future is already completed, `false` otherwise
    */
    public var isCompleted: Bool {
        switch self.state.get() {
        case is Box<Try<T>>:
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
    If the future is completed, the value will be `Try.Success(t)`
    if it contains a valid result, or `Try.Failure(error)` if it contains
    an error.
    */
    public var value: Try<T>? {
        switch self.state.get() {
        case let c as Box<Try<T>>:
            return c.unbox
            
        case is Future<T>:
            return self.compressedRoot.value
            
        default:
            return nil
        }
    }
    
    
    
    // MARK: - Monadic operations
    
    
    
    /**
    Asynchronously processes the value in the future once the value becomes available.
    
    Will not be called if the future fails.
    */
    func foreach(executionContext: ExecutionContext = defaultExecutionContext)(_ f: T -> Void) {
        return self.onComplete(executionContext)({
            $0.foreach(f)
        })
    }
    
    func foreach(f: T -> Void) {
        return self.foreach()(f)
    }
    

    /**
    Creates a new future by applying the 's' function to the successful result of
    this future, or the 'f' function to the failed result. If there is any error
    returned when 's' or 'f' is applied, that error will be propagated
    to the resulting future.
    
    - parameter s: function that transforms a successful result of the receiver into a
              successful result of the returned future
    - parameter f: function that transforms a failure of the receiver into a failure of
              the returned future
    
    - returns: a future that will be completed with the transformed value
    */
    func transform<S>(executionContext: ExecutionContext = defaultExecutionContext)(_ s: T -> S, _ f: ErrorType -> ErrorType) -> Future<S> {
        let p = Promise<S>()
        self.onComplete(executionContext)({
            switch $0 {
            case let .Success(r):
                try! p.complete(Try { s(r) })
            case let .Failure(t):
                try! p.complete(Try { throw f(t) })
            }
        })
        return p.future
    }
    
    func transform<S>(s: T -> S, _ f: ErrorType -> ErrorType) -> Future<S> {
        return transform()(s, f)
    }
    
    
    /**
    Creates a new future by applying a function to the successful result of
    this future. If this future is completed with an error then the new
    future will also contain this error.
    */
    func map<S>(executionContext: ExecutionContext = defaultExecutionContext)(_ f: T -> S) -> Future<S> {
        let p = Promise<S>()
        self.onComplete(executionContext)({
            try! p.complete($0.map(f))
        })
        return p.future
    }
    
    func map<S>(f: T -> S) -> Future<S> {
        return map()(f)
    }
    
    
    /**
    Creates a new future by applying a function to the successful result of
    this future, and returns the result of the function as the new future.
    If this future is completed with an error then the new future will
    also contain this error.
    */
    func flatMap<S>(executionContext: ExecutionContext = defaultExecutionContext)(_ f: T throws -> Future<S>) -> Future<S> {
        let p = Promise<S>()
        self.onComplete(executionContext)({
            switch $0 {
            case let .Failure(f):
                try! p.complete(Try.Failure(f))
            case .Success(let v):
                do {
                    let nv = try f(v)
                    try nv.linkRootOf(p.future)
                }
                catch {
                    try! p.failure(error)
                }
            
            }
        })
        return p.future
    }
    
    func flatMap<S>(f: T -> Future<S>) -> Future<S> {
        return flatMap()(f)
    }
    
    
    
    // MARK: - Projections
    
    
    
    /**
    Returns a failed projection of this future.
    
    The failed projection is a future holding a value of type `ErrorType`.

    It is completed with a value which is the error of the original future
    in case the original future is failed.
    
    It is failed with a `NoSuchElement` error if the original future is completed successfully.
    
    Blocking on this future returns a value if the original future is completed with an exception
    and throws a corresponding exception if the original future fails.
    */
    public var failed: Future<ErrorType> {
        let p = Promise<ErrorType>()
        self.onComplete(internalExecutionContext)({
            switch $0 {
            case let .Failure(t):
                try! p.success(t)
            case .Success(_):
                try! p.failure(Error.NoSuchElement("Future.failed not completed with an error."))
            }
        })
        return p.future
    }
    
    
    
    // MARK: - Awaitable protocol
    
    
    
    /**
    Try waiting for this promise to be completed.
    */
    internal final func tryAwait(atMost: Duration) -> Bool {
        if !self.isCompleted {
            let l = CompletionLatch()
            self.onComplete(internalExecutionContext)({ _ in
                l.apply()
            })
            l.acquire(atMost)
            
            return self.isCompleted
        } else {
            return true
        }
    }
    
    
    public func ready(atMost: Duration)(_ permit: CanAwait) throws -> Self {
        if self.tryAwait(atMost) {
            return self
        } else {
            throw Error.Timeout("Future timed out after \(atMost).")
        }
    }
    
    
    public func result(atMost: Duration)(_ permit: CanAwait) throws -> T {
        // ready() throws Timeout error if timeout so value! is safe here.
        return try self.ready(atMost)(permit).value!.get()
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
    
    - parameter value: Either the value or the error to complete the promise with.
    
    - returns: If the promise has already been completed returns `false`, or `true` otherwise.
    */
    internal func tryComplete(value: Try<T>) -> Bool {
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
    private func tryCompleteAndGetListeners(value: Try<T>) -> LinkedList<CallbackRunnable<T>>? {
        switch self.state.get() {
        case let listeners as LinkedList<CallbackRunnable<T>>:
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
        case let r as Box<Try<T>>:
            runnable.execute(r.unbox)
            
        case is Future<T>:
            self.compressedRoot.dispatchOrAddCallback(runnable)
            
        case let listeners as LinkedList<CallbackRunnable<T>>:
            let newListeners = LinkedList(runnable)
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
    internal final func linkRootOf(target: Future<T>) throws {
        try link(target.compressedRoot)
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
    private func link(target: Future<T>) throws {
        if self !== target {
            switch self.state.get() {
            case let r as Box<Try<T>>:
                if !target.tryComplete(r.unbox) {
                    // Currently linking is done from Future.flatMap, which should ensure only
                    // one promise can be completed. Therefore this situation is unexpected.
                    throw Error.IllegalState("Cannot link completed promises together")
                }
                
            case is Future<T>:
                try self.compressedRoot.link(target)
                
            case let listeners as LinkedList<CallbackRunnable<T>>:
                if self.state.update(listeners, newValue: target) {
                    for var node: LinkedList<CallbackRunnable<T>>? = listeners; node?.data != nil; node = node?.next {
                        if let callbackRunnable = node?.data {
                            target.dispatchOrAddCallback(callbackRunnable)
                        }
                    }
                } else {
                    try self.link(target)
                }
            default:
                break
            }
        }
    }

}



// MARK: -

/**
An already completed Future is given its result at creation.

Useful in Future-composition when a value to contribute is already available.
*/
internal final class CompletedFuture<T>: Future<T> {
    
    
    private var completedValue: Try<T>

    
    init(_ value: Try<T>) {
        self.completedValue = value
        super.init()
    }
    
    
    override var value: Try<T>? {
        return self.completedValue
    }
    
    override var isCompleted: Bool {
        return true
    }
    
    override func tryComplete(value: Try<T>) -> Bool {
        return false
    }
    
    override func onComplete(executionContext: ExecutionContext = defaultExecutionContext)(_ body: Try<T> throws -> Void) {
        CallbackRunnable(executionContext: executionContext.prepare(), onComplete: body).execute(completedValue)
    }
    
    override func ready(atMost: Duration)(_ permit: CanAwait) throws -> Self {
        return self
    }
    
    override func result(atMost: Duration)(_ permit: CanAwait) throws -> T {
        return try self.completedValue.get()
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
    
    var value: Try<T>? = nil
    
    private let executionContext: ExecutionContext
    
    private let onComplete: Try<T> throws -> Void
    
    
    init(executionContext: ExecutionContext, onComplete: Try<T> throws -> Void) {
        self.executionContext = executionContext
        self.onComplete = onComplete
    }
    
    func run() {
        
        precondition(value != nil, "Must set value to non-nil before running!")
        do {
            try self.onComplete(self.value!)
        }
        catch {
            self.executionContext.reportFailure(error)
        }
    }
    
    func execute(value: Try<T>) {
        
        precondition(self.value == nil, "Can't complete a promise twice.")
        
        self.value = value
        
        // Note that we cannot prepare the ExecutionContext at this point, since we might
        // already be running on a different thread!
        
        do {
            try self.executionContext.execute(self)
        }
        catch {
            self.executionContext.reportFailure(error)
        }
    }
}



// MARK: -

class PromiseCompletingRunnable<T>: Runnable {
    
    private var runnableBody: () -> () = {}
    
    
    init(future: Future<T>, body: () throws -> T) {
        
        let promise = Promise(future: future)
        self.runnableBody = {
            try! promise.complete(Try(body))
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

/**
This is used to run callbacks which are internal
to this library; our own callbacks are only
ever used to eventually run another callback,
and that other callback will have its own
executor because all callbacks come with
an executor. Our own callbacks never block
and have no "expected" exceptions.
As a result, this executor can do nothing;
some other executor will always come after
it (and sometimes one will be before it),
and those will be performing the "real"
dispatch to code outside scala.concurrent.
Because this exists, ExecutionContext.defaultExecutionContext
isn't instantiated by Future internals, so
if some code for some reason wants to avoid
ever starting up the default context, it can do so
by just not ever using it itself. scala.concurrent
doesn't need to create defaultExecutionContext as
a side effect.
*/
private final class InternalCallbackExecutor: BatchingExecutor {
    
    private override func unbatchedExecute(r: Runnable) throws {
        try r.run()
    }
    
    private override func reportFailure(cause: ErrorType) {
        fatalError("Problem in internal callback \(cause)")
    }
}




