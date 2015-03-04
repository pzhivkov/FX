//
//  ListNode.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 03/03/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//




/**
Define this a class so that it has reference semantics and so that it can participate in atomic updates.
*/
internal final class ListNode<T> {
    
    var data: T?
    
    var next: ListNode<T>?
    
    
    init() {} // Empty list.
    
    init(_ data: T) {
        self.data = data
    }
}
