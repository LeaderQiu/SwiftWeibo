//
//  NetworkManagerTests.swift
//  HMWeibo04
//
//  Created by apple on 15/3/2.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit
import XCTest

class NetworkManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    ///  测试单例
    func testSingleton() {
        let manager1 = NetworkManager.sharedManager
        let manager2 = NetworkManager.sharedManager
        
        // 在 swift 中用 === 是判断两个变量指向内存空间的对象完全一致，指向相同的内存地址
        // == 只是做两个变量之间值的判断
        XCTAssert(manager1 === manager2, "对象实例不一致")
    }
}
