//
//  ThreadLocalTests
//  FXTests
//
//  Created by Peter Zhivkov on 22/02/2015.
//  Copyright (c) 2015 Peter Zhivkov. All rights reserved.
//

import Foundation
import XCTest

@testable import FX


class ThreadLocalTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testThreadLocalValue() {
        let tl = ThreadLocal<Int>()
        
        XCTAssert(tl.get() == nil, "Non-nil initial storage.")
        
        tl.set(100)
        
        XCTAssert(tl.get() == 100, "Storage doesn't persist.")
        
        tl.set(200)
        
        XCTAssert(tl.get() == 200, "Storage doesn't change correctly.")
        
        tl.set(nil)
        
        XCTAssert(tl.get() == nil, "Storage doesn't clear.")
    }
    

    func testThreadLocalObject() {
        
        class TestObject {
            var string = ""
        }
        
        let obj = TestObject()
        obj.string = "Test"
        
        let tl = ThreadLocal<TestObject>()
        
        XCTAssert(tl.get() == nil, "Non-nil initial storage.")
        
        tl.set(obj)
        
        XCTAssert(tl.get()!.string == "Test", "Storage doesn't persist.")
    
        obj.string = "New"
        
        XCTAssert(tl.get()!.string == "New", "Storage doesn't point to object.")
        
    }
    
    
    
    func testThreadLocalObjectScope() {
        
        class TestObject: NSObject {
            var string = ""
        }
        
        let tl = ThreadLocal<TestObject>()
        
        XCTAssert(tl.get() == nil, "Non-nil initial storage.")
        
 
        autoreleasepool {
            let obj = TestObject()
            obj.string = "Test"

            tl.set(obj)
            
            XCTAssert(tl.get()!.string == "Test", "Storage doesn't persist.")
        }
        
        XCTAssert(tl.get() != nil && tl.get()!.string == "Test", "Storage doesn't persist out of scope.")
        
        autoreleasepool {
            if let oldObj = tl.get() {
                oldObj.string = "Test again"
            }
        }
        
        XCTAssert(tl.get() != nil && tl.get()!.string == "Test again", "Storage doesn't persist out of scope.")
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
