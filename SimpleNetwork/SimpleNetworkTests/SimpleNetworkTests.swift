//
//  SimpleNetworkTests.swift
//  SimpleNetworkTests
//
//  Created by apple on 15/3/2.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit
import XCTest

class SimpleNetworkTests: XCTestCase {
    
    /// 网络工具类
    let net = SimpleNetwork()
    /// 测试网络地址
    let urlString = "http://httpbin.org/get"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    ///  请求JSON － 网络访问是异步的，在 Xcode 6.0 之前，异步的单元测试相当的蛋疼
    ///  在 Xcode 4.0 的时候，苹果都不好意思把单元测试暴露出来！
    func testRequestJSON() {
        // 1. 定义一个"期望" -> 描述异步的需求，只是一个标记而已
        let expectation = expectationWithDescription(urlString)
        
        net.requestJSON(.GET, urlString, nil) { (result, error) -> () in
            println(result)
            
            // 2. 标记"期望达成"
            expectation.fulfill()
        }
        
        // 3. 等待期望达成
        // 参数时间：等待异步操作必须在10s钟之内完成
        waitForExpectationsWithTimeout(10.0, handler: { (error) -> Void in
            XCTAssertNil(error)
        })
    }
    
    /// 测试错误的网络请求
    func testErrorNetRequest() {
        net.requestJSON(.GET, "", nil) { (result, error) -> () in
            println(error)
            XCTAssertNotNil(error, "必须返回错误")
        }
    }
    
    ///  测试 POST 请求
    func testPostRequest() {
        var r = net.request(.POST, urlString, nil)
        XCTAssertNil(r, "请求应该为 nil")
        
        r = net.request(.POST, urlString, ["name": "zhang"])
        XCTAssert(r!.HTTPMethod == "POST", "访问方法不正确")
        // 测试数据体
        XCTAssert(r!.HTTPBody! == "name=zhang".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true), "数据体不正确")
    }
    
    ///  测试请求的构造
    func testGetRequest() {
        let net = SimpleNetwork()
        var r = net.request(.GET, "", nil)
        XCTAssertNil(r, "请求应该为空")
        r = net.request(.POST, "", nil)
        XCTAssertNil(r, "请求应该为空")
        
        r = net.request(.GET, urlString, nil)
        XCTAssertNotNil(r, "请求应该被建立")
        XCTAssert(r!.URL!.absoluteString == urlString, "返回的 URL 不正确")

        r = net.request(.GET, urlString, ["name": "zhangsan"])
        XCTAssert(r!.URL!.absoluteString == urlString + "?name=zhangsan", "返回的 URL 不正确")
    }
    
    ///  查询请求字符串
    func testQueryString() {
        let net = SimpleNetwork()
        
        // 断言的提示信息，可以省略，不建议省略
        // 如果时间过的很长，一旦某一个测试不通过，单纯看断言可能不明白，当初为什么测试
        XCTAssertNil(net.queryString(nil), "查询参数应该为空值")
        println(net.queryString(["name": "zhangsan"])!)
        XCTAssert(net.queryString(["name": "zhangsan"])! == "name=zhangsan")
        println(net.queryString(["name": "zhangsan", "title": "boss"])!)
        XCTAssert(net.queryString(["name": "zhangsan", "title": "boss"])! == "title=boss&name=zhangsan")
        // 测试百分号转义
        println(net.queryString(["name": "zhangsan", "book": "ios 8.0"])!)
        XCTAssert(net.queryString(["name": "zhangsan", "book": "ios 8.0"])! == "book=ios%208.0&name=zhangsan")
    }
}
