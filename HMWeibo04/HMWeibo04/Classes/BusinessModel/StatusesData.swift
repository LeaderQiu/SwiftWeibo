//
//  StatusesData.swift
//  HMWeibo04
//
//  Created by apple on 15/3/5.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit

/**
    关于业务模型

    - 专门处理"被动"的业务，模型类永远不知道谁会在什么时候调用它！
    - 准备好跟数据模型相关的数据
*/
/// 加载微博数据 URL
private let WB_Home_Timeline_URL = "https://api.weibo.com/2/statuses/home_timeline.json"

///  微博数据列表模型
class StatusesData: NSObject, DictModelProtocol {
    ///  微博记录数组
    var statuses: [Status]?
    ///  微博总数
    var total_number: Int = 0
    ///  未读数辆
    var has_unread: Int = 0
    
    static func customClassMapping() -> [String: String]? {
        return ["statuses": "\(Status.self)"]
    }
    
    ///  刷新微博数据 - 专门加载网络数据以及错误处理的回调
    ///  一旦加载成功，负责字典转模型，回调传回转换过的模型数据
    class func loadStatus(completion: (data: StatusesData?, error: NSError?)->()) {
        
        let net = NetworkManager.sharedManager
        if let token = AccessToken.loadAccessToken()?.access_token {
            let params = ["access_token": token]
            
            // 发送网络异步请求
            net.requestJSON(.GET, WB_Home_Timeline_URL, params) { (result, error) -> () in
                
                if error != nil {
                    // 错误处理
                    completion(data: nil, error: error!)
                    return
                }
                
                // 字典转模型
                var modelTools = DictModelManager.sharedManager
                var data = modelTools.objectWithDictionary(result as! NSDictionary, cls: StatusesData.self) as? StatusesData
                
                // 如果有下载图像的 url，就先下载图像
                if let urls = StatusesData.pictureURLs(data?.statuses) {
                    net.downloadImages(urls) { (_, _) -> () in
                        // 回调通知视图控制器刷新数据
                        completion(data: data, error: nil)
                    }
                } else {
                    // 如果没有要下载的图像，直接回调 -> 将模型通知给视图控制器
                    completion(data: data, error: nil)
                }
            }
        }
    }
    
    ///  取出给定的微博数据中所有图片的 URL 数组
    ///
    ///  :param: statuses 微博数据数组，可以为空
    ///
    ///  :returns: 微博数组中的 url 完整数组，可以为空
    class func pictureURLs(statuses: [Status]?) -> [String]? {
        
        // 如果数据为空直接返回
        if statuses == nil {
            return nil
        }
        
        // 遍历数组 
        var list = [String]()
        
        for status in statuses! {
            // 继续遍历 pic_urls（原创微博的图片）
            if let urls = status.pictureUrls {
                for pic in urls {
                    list.append(pic.thumbnail_pic!)
                }
            }
        }
        
        if list.count > 0 {
            return list
        } else {
            return nil
        }
    }
}

///  微博模型
class Status: NSObject, DictModelProtocol {
    ///  微博创建时间
    var created_at: String?
    ///  微博ID
    var id: Int = 0
    ///  微博信息内容
    var text: String?
    ///  微博来源
    var source: String?
    ///  转发数
    var reposts_count: Int = 0
    ///  评论数
    var comments_count: Int = 0
    ///  表态数
    var attitudes_count: Int = 0
    ///  配图数组
    var pic_urls: [StatusPictureURL]?
    
    /// 要显示的配图数组
    /// 如果是原创微博，就使用 pic_urls
    /// 如果是转发微博，使用 retweeted_status.pic_urls
    var pictureUrls: [StatusPictureURL]? {
        get {
            if retweeted_status != nil {
                return retweeted_status?.pic_urls
            } else {
                return pic_urls
            }
        }
    }
    
    /// 所有大图的 URL － 计算属性
    var largeUrls: [String]? {
        get {
            // 可以使用 kvc 直接拿值
            var urls = self.valueForKeyPath("pictureUrls.large_pic") as? NSArray
            return urls as? [String]
        }
    }
    
    /// 用户信息
    var user: UserInfo?
    /// 转发微博，如果有就是转发微博，如果没有就是原创微博
    var retweeted_status: Status?
    
    static func customClassMapping() -> [String : String]? {
        return ["pic_urls": "\(StatusPictureURL.self)",
        "user": "\(UserInfo.self)",
        "retweeted_status": "\(Status.self)",]
    }
}

///  微博配图模型
class StatusPictureURL: NSObject {
    ///  缩略图 URL
    var thumbnail_pic: String? {
        didSet {
            // 生成大图的 URL，将 thumbnail_pic 替换成 large
            // 1. 定义一个字符串
            var str = thumbnail_pic! as NSString
            // 2. 直接替换字符串
            large_pic = str.stringByReplacingOccurrencesOfString("thumbnail", withString: "large")
//            // 2. 查找thumbnail_pic在字符串中出现的范围
//            let range = (str).rangeOfString("thumbnail")
//            // 3. 处理字符串
//            // http://ww2.sinaimg.cn/thumbnail/644471aegw1epy4a544u3j20c80820te.jpg
//            //
//            // 判断是否找打对应的字符串
//            if range.location != NSNotFound {
//                // 拼接大图 url 地址
//                large_pic = str.substringToIndex(range.location) + "large" + str.substringFromIndex(range.location + range.length)
//            }
        }
    }
    
    ///  大图 URL
    var large_pic: String?
}
