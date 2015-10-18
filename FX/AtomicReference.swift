//
//  AtomicReference.swift
//  FX
//
//  Created by Peter Zhivkov on 25/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import Darwin



public final class AtomicReference<T: AnyObject> {

    private var ref: T?
    
    
    
    // MARK: - Initialization
    
    
    
    deinit {
        update(ref, newValue: nil)
    }
    
    
    
    // MARK: - Access
    
    
    
    public func get() -> T? {
        return ref
    }
    
    
    public func update(oldValue: T?, newValue: T?) -> Bool {
        
        return withUnsafeMutablePointer(&self.ref) { (state) -> Bool in
            
            let statePtr = UnsafeMutablePointer<UnsafeMutablePointer<Void>>(state)
            
            let oldValueRef: Unmanaged<AnyObject>! = oldValue == nil ? nil : Unmanaged<AnyObject>.passUnretained(oldValue!)
            let newValueRef: Unmanaged<AnyObject>! = newValue == nil ? nil : Unmanaged<AnyObject>.passUnretained(newValue!)
            
            let oldValuePtr: UnsafeMutablePointer<Void> = oldValue == nil ? nil : UnsafeMutablePointer<Void>(oldValueRef.toOpaque())
            let newValuePtr: UnsafeMutablePointer<Void> = newValue == nil ? nil : UnsafeMutablePointer<Void>(newValueRef.toOpaque())

            if OSAtomicCompareAndSwapPtrBarrier(oldValuePtr, newValuePtr, statePtr) {
                oldValueRef?.release()
                newValueRef?.retain()
                return true
            } else {
                return false
            }
        }
    }
    
}

