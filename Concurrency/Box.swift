//
//  Box.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 28/06/2015.
//  Copyright © 2015 Peter Zhivkov. All rights reserved.
//

import Foundation


internal class Box<T> {
    let unbox: T
    init(_ value: T) { self.unbox = value }
}

