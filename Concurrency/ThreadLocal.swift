//
//  ThreadLocal.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 21/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import Foundation



/**
*  Thread-local storage
*/
public class ThreadLocal<T> {
    
    private var key: pthread_key_t = 0

    
    
    // MARK: - Initialization
    
    

    public init() {
        var ret = Int32(0)
        do {
            // Since Swift initializers are guaranteed to be idempotent, there is no need
            // to use pthread_once() here for the key creation.
            ret = pthread_key_create(&key, mem_destructorFunc(type: T.self))
            switch ret {
            case EAGAIN:
                debugPrintln("Can't create key for thread-local storage due to lack of resources or too many keys.")
            case ENOMEM:
                debugPrintln("Not enough memory to create key for thread-local storage.")
            default:
                break
            }
        } while ret != 0
    }
    
    
    deinit {
        let ret = pthread_key_delete(key)
        if ret == EINVAL {
            debugPrintln("Attempted to delete an invalid key (\(key)) for thread-local storage.")
        }
    }
    
    
    
    // MARK: - Access
    
    
    
    /**
    Get the value in the thread-local storage.
    
    :returns: The thread-local value.
    */
    public func get() -> T? {
        let ptr = UnsafeMutablePointer<T>(pthread_getspecific(key))
        if ptr == nil {
            return nil
        }

        return ptr[0]
    }
    
    
    /**
    Set a value in the thread-local storage.
    
    :param: obj The new value to be set for the current thread.
    */
    public func set(obj: T?) {
        var ptr = UnsafeMutablePointer<T>(pthread_getspecific(key))
        if ptr != nil {
            if obj != nil && self.areSame(ptr[0], obj!) {
                return
            }
            mem_releaseStorage(ptr)
        }
        ptr = obj != nil ? mem_retainStorage(obj!) : nil
        
        let ret = pthread_setspecific(key, ptr)
        switch ret {
        case ENOMEM:
            debugPrintln("Insufficient memory to look up thread-local storage for key \(key).")
        case EINVAL:
            debugPrintln("Attemped to look up thread-local storage for invalid key \(key).")
        default:
            break
        }
    }
    
    
    
    // MARK: - Equality
    
    
    
    private func areSame<T: Equatable>(obj1: T, _ obj2: T) -> Bool { return obj1 == obj2 }
    
    private func areSame(obj1: T, _ obj2: T) -> Bool { return false }
    
}
