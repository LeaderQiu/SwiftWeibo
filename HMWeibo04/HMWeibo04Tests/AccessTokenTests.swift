//
//  AccessTokenTests.swift
//  HMWeibo04
//
//  Created by apple on 15/3/3.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit
import XCTest

class AccessTokenTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testIsExpired() {
        var dict = ["access_token": "2.00ml8IrFcgjGyC3a36539d80SOuztB",
        "expires_in": 1,
        "remind_in": 157679999,
            "uid": 5365823342]
        
        var token = AccessToken(dict: dict)
        println(token.isExpired)
        
        dict = ["access_token": "2.00ml8IrFcgjGyC3a36539d80SOuztB",
            "expires_in": 0,
            "remind_in": 157679999,
            "uid": 5365823342]
        
        token = AccessToken(dict: dict)
        println(token.isExpired)
        
        dict = ["access_token": "2.00ml8IrFcgjGyC3a36539d80SOuztB",
            "expires_in": -1,
            "remind_in": 157679999,
            "uid": 5365823342]
        
        token = AccessToken(dict: dict)
        println(token.isExpired)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}
