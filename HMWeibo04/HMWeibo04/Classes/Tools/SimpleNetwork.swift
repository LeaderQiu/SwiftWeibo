//
//  SimpleNetwork.swift
//  SimpleNetwork
//
//  Created by apple on 15/3/2.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import Foundation

///  常用的网络访问方法
public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
}

public class SimpleNetwork {

    // 定义闭包类型，类型别名－> 首字母一定要大写
    public typealias Completion = (result: AnyObject?, error: NSError?) -> ()
    
    func demoGCDGroup() {
        /**
        dispatch_group_async(dispatch_group_t group, dispatch_queue_t queue, dispatch_block_t block)
        {
            dispatch_retain(group);
        
            // 一旦使用了 enter，后续的 block 就会被 group 监听
            dispatch_group_enter(group);
        
            dispatch_async(queue, ^{
                block();
        
                // 异步执行完毕之后，必须要使用 dispatch_group_leave
                dispatch_group_leave(group);
        
                dispatch_release(group);
                });
        }
        */
        
        // 利用调度组统一监听一组异步任务执行完毕
        let group = dispatch_group_create()
        
        dispatch_group_async(group, dispatch_get_global_queue(0, 0)) { () -> Void in
            
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            // 所有任务完成后的回调
        }
    }
    
    ///  下载多张图片
    ///
    ///  :param: urls       图片 URL 数组
    ///  :param: completion 所有图片下载完成后的回调
    func downloadImages(urls: [String], _ completion: Completion) {
 
        // 希望所有图片下载完成，统一回调！
        
        // 利用调度组统一监听一组异步任务执行完毕
        let group = dispatch_group_create()
        
        // 遍历数组
        for url in urls {
            // 进入调度组
            dispatch_group_enter(group)
            downloadImage(url) { (result, error) -> () in
                // 一张图片下载完成，会自动保存在缓存目录
                // 下载多张图片的时候，有可能有些有错误，有些没错误！
                // 暂时不处理
                
                // 离开调度组
                dispatch_group_leave(group)
            }
        }

        // 在主线程回调
        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            // 所有任务完成后的回调
            completion(result: nil, error: nil)
        }
    }
    
    ///  下载图像并且保存到沙盒
    ///
    ///  :param: urlString  urlString
    ///  :param: completion 完成回调
    func downloadImage(urlString: String, _ completion: Completion) {
        
        // 1. 将下载的图像 url 进行 md5
        var path = urlString.md5
        // 2. 目标路径
        path = cachePath!.stringByAppendingPathComponent(path)
        
        // 2.1 缓存检测，如果文件已经下载完成直接返回
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            println("\(urlString) 图片已经被缓存")
            completion(result: nil, error: nil)
            return
        }
        
        // 3. 下载图像
        if let url = NSURL(string: urlString) {
            self.session!.downloadTaskWithURL(url) { (location, _, error) -> Void in
                
                // 错误处理
                if error != nil {
                    completion(result: nil, error: error)
                    return
                }
                
                // 将文件复制到缓存路径
                NSFileManager.defaultManager().copyItemAtPath(location.path!, toPath: path, error: nil)
                
                // 直接回调，不传递任何参数
                completion(result: nil, error: nil)
            }.resume()
        }
    }
    
    /// 完整图像缓存路径
    lazy var cachePath: String? = {
        // 1. cache
        var path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true).last as! String
        path = path.stringByAppendingPathComponent(imageCachePath)
        
        // 2. 检查缓存路径是否存在 － 注意：必须准确地指出类型 ObjCBool
        var isDirectory: ObjCBool = true
        // 无论存在目录还是文件，都会返回 true，是否是路径由 isDirectory 来决定
        let exists = NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDirectory)
        println("isDirectory： \(isDirectory) exists \(exists) path: \(path)")
        
        // 3. 如果有同名的文件－干掉 
        // 一定需要判断是否是文件，否则目录也同样会被删除
        if exists && !isDirectory {
            NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
        }
        
        // 4. 直接创建目录，如果目录已经存在，就什么都不做
        // withIntermediateDirectories -> 是否智能创建层级目录
        NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil, error: nil)
        
        return path
    }()
    
    /// 缓存路径的常量 - 类变量不能存储内容，但是可以返回数值
    private static var imageCachePath = "com.itheima.imagecache"
    
    // MARK: - 请求 JSON
    ///  请求 JSON
    ///
    ///  :param: method     HTTP 访问方法
    ///  :param: urlString  urlString
    ///  :param: params     可选参数字典
    ///  :param: completion 完成回调
    public func requestJSON(method: HTTPMethod, _ urlString: String, _ params: [String: String]?, completion: Completion) {
        
        // 实例化网络请求
        if let request = request(method, urlString, params) {

            // 访问网络 － 本身的回调方法是异步的
            session!.dataTaskWithRequest(request, completionHandler: { (data, _, error) -> Void in
                
                println(request)
                
                // 如果有错误，直接回调，将网络访问的错误传回
                if error != nil {
                    completion(result: nil, error: error)
                    return
                }
                
                // 反序列化 -> 字典或者数组
                let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: nil)
                
                // 判断是否反序列化成功
                if json == nil {
                    let error = NSError(domain: SimpleNetwork.errorDomain, code: -1, userInfo: ["error": "反序列化失败"])
                    completion(result: nil, error: error)
                } else {
                    // 有结果
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion(result: json, error: nil)
                    })
                }
            }).resume()
            
            return
        }
        // 如果网络请求没有创建成功，应该生成一个错误，提供给其他的开发者
        /**
            domain: 错误所属领域字符串 com.itheima.error
            code: 如果是复杂的系统，可以自己定义错误编号
            userInfo: 错误信息字典
        */
        let error = NSError(domain: SimpleNetwork.errorDomain, code: -1, userInfo: ["error": "请求建立失败"])
        completion(result: nil, error: error)
    }
    
    // 静态属性，在 Swift 中类属性可以返回值但是不能存储数值
    static let errorDomain = "com.itheima.error"
    
    ///  返回网络访问的请求
    ///
    ///  :param: method    HTTP 访问方法
    ///  :param: urlString urlString
    ///  :param: params    可选参数字典
    ///
    ///  :returns: 可选网络请求
    func request(method: HTTPMethod, _ urlString: String, _ params: [String: String]?) -> NSURLRequest? {
        
        // isEmpty 是 "" & nil
        if urlString.isEmpty {
            return nil
        }
        
        // 记录 urlString，因为传入的参数是不可变的
        var urlStr = urlString
        var r: NSMutableURLRequest?
        
        if method == .GET {
            // URL 的参数是拼接在URL字符串中的
            // 1. 生成查询字符串
            let query = queryString(params)
            
            // 2. 如果有拼接参数
            if query != nil {
                urlStr += "?" + query!
            }
            
            // 3. 实例化请求
            r = NSMutableURLRequest(URL: NSURL(string: urlStr)!)
        } else {
            
            // 设置请求体，提问：post 访问，能没有请求体吗？=> 必须要提交数据给服务器
            if let query = queryString(params) {
                r = NSMutableURLRequest(URL: NSURL(string: urlStr)!)
                
                // 设置请求方法
                // swift 语言中，枚举类型，如果要去的返回值，需要使用一个 rawValue
                r!.HTTPMethod = method.rawValue

                // 设置数据提
                r!.HTTPBody = query.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
            }
        }
        
        return r
    }
    
    ///  生成查询字符串
    ///
    ///  :param: params 可选字典
    ///
    ///  :returns: 拼接完成的字符串
    func queryString(params: [String: String]?) -> String? {
        
        // 0. 判断参数
        if params == nil {
            return nil
        }
        
        // 涉及到数组的使用技巧
        // 1. 定义一个数组
        var array = [String]()
        // 2. 遍历字典
        for (k, v) in params! {
            let str = k + "=" + v.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            array.append(str)
        }
        
        return join("&", array)
    }
    
    ///  公共的初始化函数，外部就能够调用了
    public init() {}
    
    ///  全局网络会话，提示，可以利用构造函数，设置不同的网络会话配置
    lazy var session: NSURLSession? = {
        return NSURLSession.sharedSession()
    }()
}
