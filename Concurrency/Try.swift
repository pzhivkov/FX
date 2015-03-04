//
//  Try.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 24/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//



/**
The `Try` type represents a computation that may either result in an exception, or return a
successfully computed value.

Instances of `Try<T>`, are either Success or Failure.

An important property of `Try` shown in the above example is its ability to ''pipeline'', or chain, operations,
catching exceptions along the way. The `flatMap` and `map` combinators in the above example each essentially
pass off either their successfully completed value, wrapped in the `Success` type for it to be further operated
upon by the next combinator in the chain, or the exception wrapped in the `Failure` type usually to be simply
passed on down the chain. Combinators such as `recover` and `recoverWith` are designed to provide some type of
default behavior in the case of failure.
*/
public enum Try<T> {
  
    case Success(T)
    
    case Failure(ErrorType)
    
    
    
    // MARK: - Initializaiton
    
    
    
    public init(@noescape _ body: () throws -> T) {
        do {
            self = try .Success(body())
        } catch {
            self = .Failure(error)
        }
    }
    
    
    
    // MARK: - State tests
    
    
    
    ///  Returns `true` if the `Try` is a `Failure`, `false` otherwise.
    public var isFailure: Bool {
        if case .Failure = self {
            return true
        }
        return false
    }
    
    
    /// Returns `true` if the `Try` is a `Success`, `false` otherwise.
    public var isSuccess: Bool {
        if case .Success = self {
            return true
        }
        return false
    }
    
    
    
    // MARK: - Transforms
    
    
    
    /**
    Returns the value from this `Success` or the given `default` argument if this is a `Failure`.
    
    ''Note:'': This will throw an error if it is not a success and default throws an error.
    */
    public func getOrElse(@autoclosure defaultValue: () throws -> T) throws -> T {
        if isSuccess {
            return try! get()
        }
        return try defaultValue()
    }
    
    public func getOrElse(@autoclosure defaultValue: () -> T) -> T {
        if isSuccess {
            return try! get()
        }
        return defaultValue()
    }
    
    
    /**
    Returns this `Try` if it's a `Success` or the given `default` argument if this is a `Failure`.
    */
    public func orElse(@autoclosure defaultValue: () throws -> Try<T>) -> Try<T> {
        do {
            if isSuccess {
                return self
            }
            return try defaultValue()
        } catch {
            return .Failure(error)
        }
    }
    
    
    /**
    Returns the value from this `Success` or throws the error if this is a `Failure`.
    */
    public func get() throws -> T {
        switch self {
        case let .Success(value):
            return value
        case let .Failure(error):
            throw error
        }
    }
    
    
    /**
    Applies the given function `f` if this is a `Success`, otherwise returns if this is a `Failure`.
    
    ''Note:'' If `f` throws, then this method may throw an error.
    */
    public func foreach<U>(@noescape f: T throws -> U) throws {
        if case let .Success(value) = self {
            try f(value)
        }
    }
    
    public func foreach<U>(@noescape f: T -> U) {
        if case let .Success(value) = self {
            f(value)
        }
    }
    
    
    /**
    Returns the given function applied to the value from this `Success` or returns this if this is a `Failure`
    */
    public func flatMap<U>(@noescape f: T throws -> Try<U>) -> Try<U> {
        switch self {
        case let .Success(value):
            do {
                return try f(value)
            } catch {
                return .Failure(error)
            }
        case let .Failure(error):
            return .Failure(error)
        }
    }
    
    
    /**
    Maps the given function to the value from this `Success` or returns this if this is a `Failure`.
    */
    public func map<U>(@noescape f: T throws -> U) -> Try<U> {
        switch self {
        case let .Success(value):
            return Try<U> { try f(value) }
        case let .Failure(error):
            return .Failure(error)
        }
    }
    
    
    /**
    Converts this to a `Failure` if the predicate is not satisfied.
    */
    public func filter(@noescape p: T throws -> Bool) -> Try<T> {
        switch self {
        case let .Success(value):
            do {
                if try p(value) {
                    return self
                } else {
                    return .Failure(Error.NoSuchElement("Predicate does not hold for \(value)"))
                }
            } catch {
                return .Failure(error)
            }
        case .Failure:
            return self
        }
    }
    
    
    /**
    Applies the given function `f` if this is a `Failure`, otherwise returns this if this is a `Success`.
    This is like `flatMap` for the error.
    */
    public func recoverWith(@noescape f: ErrorType throws -> Try<T>) -> Try<T> {
        switch self {
        case .Success:
            return self
        case let .Failure(error):
            do {
                return try f(error)
            } catch {
                return .Failure(error)
            }
        }
    }
    
    
    /** 
    Applies the given function `f` if this is a `Failure`, otherwise returns this if this is a `Success`.
    */
    public func recover(@noescape f: ErrorType throws -> T) -> Try<T> {
        switch self {
        case .Success:
            return self
        case let .Failure(error):
            return Try { try f(error) }
        }
    }
    
    /**
    Returns `None` if this is a `Failure` or a `Some` containing the value if this is a `Success`.
    */
    public var toOptional: T? {
        if isSuccess {
            return try! get()
        } else {
            return nil
        }
    }
    
    
    ///  Inverts this `Try`. If this is a `Failure`, returns its exception wrapped in a `Success`. 
    ///  If this is a `Success`, returns a `Failure` containing an `UnsupportedOperation` error.
    public var failed: Try<ErrorType> {
        switch self {
        case let .Failure(error):
            return .Success(error)
        case .Success:
            return .Failure(Error.UnsupportedOperation("Success.failed"))
        }
    }
    
    
    /**
    Completes this `Try` by applying the function `f` to this if this is of type `Failure`, or conversely, by applying
    `s` if this is a `Success`.
    */
    public func transform<U>(@noescape s: T throws -> Try<U>, @noescape f: ErrorType throws -> Try<U>) -> Try<U> {
        do {
            switch self {
            case let .Success(value):
                return try s(value)
            case let .Failure(error):
                return try f(error)
            }
        } catch {
            return .Failure(error)
        }
    }
}



/**
A coalescing infix operator for `Try`. Equivalent to `Try.getOrElse()`
*/
public func ??<T>(result: Try<T>, @autoclosure defaultValue: () -> T) -> T {
    return result.getOrElse(defaultValue)
}

