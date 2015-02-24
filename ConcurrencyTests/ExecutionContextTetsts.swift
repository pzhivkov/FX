//
//  ExecutionContextTetsts.swift
//  Concurrency
//
//  Created by Peter Zhivkov on 24/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import Foundation
import XCTest


import Concurrency



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
        defaultExecutionContext.execute({
            i++
        })
        
        XCTAssert(i == 1, "Execution failure")
    }


}
