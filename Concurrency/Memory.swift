//
//  Memory.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 22/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import Darwin.C.stdlib



/// Memory management



func mem_destructorFunc<T>(type: T.Type = T.self) -> CFunctionPointer<((UnsafeMutablePointer<Void>) -> Void)> {
    return mem_free_func()
}


func mem_destructorFunc<T: AnyObject>(type: T.Type = T.self) -> CFunctionPointer<((UnsafeMutablePointer<Void>) -> Void)> {
    return mem_release_func()
}



func mem_retainStorage<T>(obj: T) -> UnsafeMutablePointer<T> {
    let ptr = UnsafeMutablePointer<T>(malloc(UInt(sizeofValue(obj))))
    ptr.initialize(obj)
    return ptr
}


func mem_releaseStorage<T>(ptr: UnsafeMutablePointer<T>) {
    if ptr != nil {
        ptr.destroy()
        free(ptr)
    }
}



func mem_retainStorage<T: AnyObject>(obj: T) -> UnsafeMutablePointer<T> {
    let retainedOpaque = Unmanaged<T>.passRetained(obj).toOpaque()
    return UnsafeMutablePointer<T>(retainedOpaque)
}


func mem_releaseStorage<T: AnyObject>(ptr: UnsafeMutablePointer<T>) {
    if ptr != nil {
        Unmanaged<T>.fromOpaque(COpaquePointer(ptr)).release()
    }
}
    
