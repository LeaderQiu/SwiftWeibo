//
//  NetworkManager.swift
//  HMWeibo04
//
//  Created by apple on 15/3/2.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import Foundation

///  网路访问接口 - 单例
///  用来隔离应用程序和第三方框架之间的网络访问
///  最后，会做一个网络的一个管理器，包括要实现最大并发数的限制！
class NetworkManager {
    
    // 单例的概念：
    // 1. 内存中有一个唯一的实例
    // 2. 提供唯一的全局访问入口
    // let 是定义常量，而且在 swift 中，let 是线程安全的
    private static let instance = NetworkManager()
    /// 定义一个类变量，提供全局的访问入口，类变量不能存储数值，但是可以返回数值
    class var sharedManager: NetworkManager {
        return instance
    }
    
    // 定义了一个类的完成闭包类型
    typealias Completion = (result: AnyObject?, error: NSError?) -> ()

    ///  请求 JSON
    ///
    ///  :param: method     HTTP 访问方法
    ///  :param: urlString  urlString
    ///  :param: params     可选参数字典
    ///  :param: completion 完成回调
    func requestJSON(method: HTTPMethod, _ urlString: String, _ params: [String: String]?, _ completion: Completion) {
        
        net.requestJSON(method, urlString, params, completion)
    }
    
    ///  异步下载网路图像
    ///
    ///  :param: urlString  urlString
    ///  :param: completion 完成回调
    func requestImage(urlString: String, _ completion: Completion) {
        
        net.requestImage(urlString, completion)
    }
    
    ///  完整的 URL 缓存路径
    func fullImageCachePath(urlString: String) -> String {
        
        return net.fullImageCachePath(urlString)
    }
    
    ///  下载多张图片
    ///
    ///  :param: urls       图片 URL 数组
    ///  :param: completion 所有图片下载完成后的回调
    func downloadImages(urls: [String], _ completion: Completion) {
        
        net.downloadImages(urls, completion)
    }
    
    ///  下载图像并且保存到沙盒
    ///
    ///  :param: urlString  urlString
    ///  :param: completion 完成回调
    func downloadImage(urlString: String, _ completion: Completion) {
        
        net.downloadImage(urlString, completion)
    }
    
    func postUpload(urlString: String, params: [String: String]?, fieldName: String, dataList: [NSData], filenames: [String], completion: Completion) {
        
        net.postUpload(urlString, params: params, fieldName: fieldName, dataList: dataList, filenames: filenames, completion: completion)
    }

    ///  全局的一个网络框架实例，本身也只会被实例化一次
    private let net = SimpleNetwork()
}
