//
//  AtomicReference.swift
//  FX
//
//  Created by Peter Zhivkov on 25/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import Darwin



public class AtomicReference<T: AnyObject>: CustomStringConvertible, CustomDebugStringConvertible {

    private var value: T?
    
    
    
    // MARK: - Initialization
    
    
    
    /**
    Creates a new AtomicReference with the given initial value.
    */
    init(value: T? = nil) {
        self.set(value)
    }
    
    
    deinit {
        self.set(nil)
    }
    
    
    
    // MARK: - Access
    
    
    
    /**
    Gets the current value.
    */
    public final func get() -> T? {
        return value
    }
    
    
    /**
    Sets to the given value.
    */
    public final func set(newValue: T?) {
        var set = false
        while (!set) {
            withExtendedLifetime(self.value) {
                if (self.compareAndSet(self.value, newValue)) {
                    set = true
                }
            }
        }
    }
    
    
    /**
    Eventually sets to the given value.
    */
    public final func lazySet(newValue: T?) {
        var set = false
        while (!set) {
            withExtendedLifetime(self.value) {
                if (self.weakCompareAndSet(self.value, newValue)) {
                    set = true
                }
            }
        }
    }
    
    
    /**
    Atomically sets to the given value and returns the old value.
    */
    public final func getAndSet(newValue: T?) -> T? {
        var set = false
        var oldValue: T?
        while (!set) {
            withExtendedLifetime(self.value, { (keptOldValue: T?) -> () in
                if (self.compareAndSet(self.value, newValue)) {
                    set = true
                    oldValue = keptOldValue
                }
            })
        }
        return oldValue
    }
    
    
    /**
    Atomically sets the value to the given updated value if the current value == the expected value.
    */
    public final func compareAndSet(oldValue: T?, _ newValue: T?) -> Bool {
        
        return withUnsafeMutablePointer(&self.value) { (reference) -> Bool in
            
            let referencePtr = UnsafeMutablePointer<UnsafeMutablePointer<Void>>(reference)
            
            let oldValueRef: Unmanaged<AnyObject>! = oldValue == nil ? nil : Unmanaged<AnyObject>.passUnretained(oldValue!)
            let newValueRef: Unmanaged<AnyObject>! = newValue == nil ? nil : Unmanaged<AnyObject>.passUnretained(newValue!)
            
            let oldValuePtr = oldValueRef == nil ? nil : UnsafeMutablePointer<Void>(oldValueRef.toOpaque())
            let newValuePtr = newValueRef == nil ? nil : UnsafeMutablePointer<Void>(newValueRef.toOpaque())

            if OSAtomicCompareAndSwapPtrBarrier(oldValuePtr, newValuePtr, referencePtr) {
                oldValueRef?.release()
                newValueRef?.retain()
                return true
            } else {
                return false
            }
        }
    }
    
    
    /**
    Atomically sets the value to the given updated value if the current value == the expected value.
    */
    public final func weakCompareAndSet(oldValue: T?, _ newValue: T?) -> Bool {
        
        return withUnsafeMutablePointer(&self.value) { (reference) -> Bool in
            
            let referencePtr = UnsafeMutablePointer<UnsafeMutablePointer<Void>>(reference)
            
            let oldValueRef: Unmanaged<AnyObject>! = oldValue == nil ? nil : Unmanaged<AnyObject>.passUnretained(oldValue!)
            let newValueRef: Unmanaged<AnyObject>! = newValue == nil ? nil : Unmanaged<AnyObject>.passUnretained(newValue!)
            
            let oldValuePtr = oldValueRef == nil ? nil : UnsafeMutablePointer<Void>(oldValueRef.toOpaque())
            let newValuePtr = newValueRef == nil ? nil : UnsafeMutablePointer<Void>(newValueRef.toOpaque())
            
            if OSAtomicCompareAndSwapPtr(oldValuePtr, newValuePtr, referencePtr) {
                oldValueRef?.release()
                newValueRef?.retain()
                return true
            } else {
                return false
            }
        }
    }
    
    
    
    // MARK: - CustomStringConvertible
    
    
    
    public var description: String {
        return "\(self.get())"
    }
    
    
    
    // MARK: - CustomDebugStringConvertible
    
    
    
    public var debugDescription: String {
        return "\(self.get())"
    }
    
}

