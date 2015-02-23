//
//  BlockContext.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 21/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//



let queueLocalContext = QueueLocal<BlockContext>()



public protocol BlockContext {
    func blockOn<T>(thunk: () -> T)(_ permission: CanAwait) -> T
}



public class BlockContextState {
    
    private class DefaultBlockContext : BlockContext {
        private func blockOn<T>(thunk: () -> T)(_ permission: CanAwait) -> T {
            return thunk()
        }
    }
    
    private static let defaultBlockContext = DefaultBlockContext()

    private static let contextLocal = ThreadLocal<BlockContext>()
    
    
    
    public static var current: BlockContext {
        if let local = contextLocal.get() {
            return local
        } else if let queueLocal = queueLocalContext.get() {
            return queueLocal
        } else {
            return defaultBlockContext
        }
    }
    
    
    public class func withBlockContext<T>(blockContext: BlockContext)(body: () -> T) -> T {
        let old = BlockContextState.contextLocal.get() // Can be nil.
        BlockContextState.contextLocal.set(blockContext)
        let ret = body()
        BlockContextState.contextLocal.set(old)
        return ret
    }
    
}



public func blocking<T>(body: () -> T) -> T {
    return BlockContextState.current.blockOn(body)(awaitPermission)
}

