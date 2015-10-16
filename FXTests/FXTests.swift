//
//  FXTests.swift
//  FXTests
//
//  Created by Peter Zhivkov on 15/10/2015.
//  Copyright © 2015 Peter Zhivkov. All rights reserved.
//

import XCTest
@testable import FX

class FXTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
            
            let p = Future<Int> {
                print("10\n", terminator: "")
                sleep(UInt32(4))
                //throw Error.IllegalState("Bad state")
                return 10
            }
            
            //println("Future returned \(Await.result(p, atMost: 5.seconds))")
            
            for i in 1..<10 {
                p.onComplete {
                    if $0.isFailure {
                        print("Failure \($0)")
                        return
                    }
                    let value = try! i + 10 + $0.get()
                    
                    blocking { () -> Void in
                        sleep(UInt32(i))
                        print("\(i) \(value)\n", terminator: "")
                    }
                }
            }
        }
    }
    
}
