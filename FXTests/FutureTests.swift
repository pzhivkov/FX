//
//  FutureTests.swift
//  FX
//
//  Created by Peter Zhivkov on 18/10/2015.
//  Copyright © 2015 Peter Zhivkov. All rights reserved.
//

import XCTest

@testable import FX



class FutureTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testFilter() {

        let f = Future { 5 }
        let g = f.filter { $0 % 2 == 1 }
        let h = f.filter { $0 % 2 == 0 }
        
        let gResult = Try { try Await.result(g, atMost: Duration.Zero) }
        let hResult = Try { try Await.result(h, atMost: Duration.Zero) }
        
        XCTAssertEqual(gResult.getOrElse(0), 5, "Filter failure")
        XCTAssertEqual(hResult.getOrElse(-1), -1, "Filter failure")
    }


}
