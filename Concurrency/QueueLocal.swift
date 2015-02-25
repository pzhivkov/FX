//
//  QueueLocal.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 22/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import Dispatch




/**
*  Queue-local storage
*/
public class QueueLocal<T> {
 
    
    private var key = UnsafePointer<Void>()
    
    
    
    // MARK: - Initialization
    
    
    /**
    Create a new queue-local storage.
    
    Note: It is required that the object should be created in global or static scope.
    
    :returns: The queue-local storage.
    */
    public init() {
        self.key = unsafeAddressOf(self)
    }
    
    
    
    // MARK: - Access
    
    
    
    /**
    Get the value in the queue-local storage for the current queue.
    
    :returns: The queue-local value.
    */
    func get() -> T! {
        let ptr = UnsafeMutablePointer<T>(dispatch_get_specific(key))
        if ptr == nil {
            return nil
        }
        
        return ptr[0]
    }
    

    
    /**
    Set a value in the queue-local storage for a given queue.
    
    :param: queue The queue on which a the value will be set.
    :param: value The value.
    */
    func set(value: T?, queue: dispatch_queue_t) {
        
        var ptr = UnsafeMutablePointer<T>(dispatch_queue_get_specific(queue, key))
        if ptr != nil {
            if value != nil && self.areSame(ptr[0], value!) {
                return
            }
            mem_releaseStorage(ptr)
        }
        ptr = value != nil ? mem_retainStorage(value!) : nil
        
        dispatch_queue_set_specific(queue, key, ptr, mem_destructorFunc(type: T.self))
    }
    
    
    
    // MARK: - Equality
    
    
    
    private func areSame<T: Equatable>(obj1: T, _ obj2: T) -> Bool { return obj1 == obj2 }
    
    private func areSame(obj1: T, _ obj2: T) -> Bool { return false }
    
}

