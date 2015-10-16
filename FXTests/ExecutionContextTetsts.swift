//
//  ExecutionContextTetsts.swift
//  Effects
//
//  Created by Peter Zhivkov on 24/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import Foundation
import XCTest


@testable import FX



class ExecutionContextTetsts: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    func testRunTask() {
        
        var i = 0
        try! defaultExecutionContext.execute(DefaultRunnable {
            i++
        })
        sleep(1)
        
        XCTAssert(i == 1, "Execution failure")
    }
    
    
    func testRunBlockingTask() {
        
        var i = 0
        try! defaultExecutionContext.execute(DefaultRunnable {
            i++
            
            XCTAssert(i == 1, "Execution failure")
            
            let res = blocking({() -> Int in
                sleep(1)
                return i++
            })
            
            XCTAssert(res == 1, "Execution failure")
            XCTAssert(i == 2, "Execution failure")
        })
        
        sleep(2)
        XCTAssert(i == 2, "Execution failure")
    }

}
