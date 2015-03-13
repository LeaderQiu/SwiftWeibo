//
//  AccessToken.swift
//  HMWeibo04
//
//  Created by apple on 15/3/3.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit

/**
    归档 NSCoding，实现两个方法
*/
/**
    AccessToken 是后续所有网络访问的重要依据
*/
class AccessToken: NSObject, NSCoding {
    ///  用于调用access_token，接口获取授权后的access token。
    var access_token: String?
    ///  access_token的生命周期，单位是秒数。
    ///  从微博服务器返回的 token 是有有效期的
    ///  如果是开发者自己，时间是 5 年，如果是其他用户，时间是 2/3 天
    ///  如果不是在有效期，需要让用户重新登录！
    var expires_in: NSNumber? {
        didSet {
            expiresDate = NSDate(timeIntervalSinceNow: expires_in!.doubleValue)
            println("过期日期 \(expiresDate)")
        }
    }

    ///  token过期日期
    var expiresDate: NSDate?
    /// 是否过期－用过期日期和当前时间进行比较
    var isExpired: Bool {
        return expiresDate?.compare(NSDate()) == NSComparisonResult.OrderedAscending
    }
    
    ///  access_token的生命周期（该参数即将废弃，开发者请使用expires_in）。
    var remind_in: NSNumber?
    ///  当前授权用户的UID，可以通过这个 id 获取用户的进一步信息
    ///  整数类型如果要归档&接档，需要使用 Int 类型，NSNumber 会不正常！
    var uid : Int = 0
    
    ///  构造函数，一旦写了，init 会被忽略
    init(dict: NSDictionary) {
        super.init()
        
        self.setValuesForKeysWithDictionary(dict as [NSObject : AnyObject])
    }
    
    ///  将数据保存到沙盒
    func saveAccessToken() {
        NSKeyedArchiver.archiveRootObject(self, toFile: AccessToken.tokenPath())
    }

    ///  从沙盒读取 token 数据
    class func loadAccessToken() -> AccessToken? {
        return NSKeyedUnarchiver.unarchiveObjectWithFile(tokenPath()) as? AccessToken
    }

    ///  返回保存在沙盒的路径
    class func tokenPath() -> String {
        var path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).last as! String
        path = path.stringByAppendingPathComponent("WBToken.plist")
        
        return path
    }
    
    // 至少要有一个 init 方法，否则外部没有办法直接实例化对象
//    override init() {}
    
    // MARK: - 归档&接档，如果不指定键名，会使用 属性名称作为 key
    // 如果写了归档和接档方法，至少需要有一个构造函数
    ///  归档方法
    func encodeWithCoder(encoder: NSCoder) {
        encoder.encodeObject(access_token)
        encoder.encodeObject(expiresDate)
        // 如果是基本数据类型，需要指定 key
        encoder.encodeInteger(uid, forKey: "uid")
    }

    ///  解档方法，NSCoding 需要的方法 － required 的构造函数不能写在 extension 中
    ///  覆盖构造函数
    required init(coder decoder: NSCoder) {
        access_token = decoder.decodeObject() as? String
        expiresDate = decoder.decodeObject() as? NSDate
        uid = decoder.decodeIntegerForKey("uid")
    }
}

///  extension 是一个分类，分类不允许有存储能力
///  如果要打印对象信息，OC 中的 description，在 swift 中需要遵守协议 DebugPrintable
extension AccessToken: DebugPrintable {
    
    override var debugDescription: String {
        let dict = self.dictionaryWithValuesForKeys(["access_token", "expiresDate", "uid"])
        return "\(dict)"
    }
}
