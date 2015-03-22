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
    ///  增加一个 max_id 的参数，就能够支持上拉加载数据，max_id 如果等于 0，就是刷新最新的数据！
    ///  maxId: Int = 0，指定函数的参数默认数值，如果不传，就是 0
    ///  topId: 是视图控制器中 statues 的第一条微博的 id，topId 和 maxId 之间就是 statuses 中的所有数据
    class func loadStatus(maxId: Int = 0, topId: Int, completion: (data: StatusesData?, error: NSError?)->()) {
        
        // TODO: - 上拉刷新，判断是否可以从本地缓存加载数据
        if maxId > 0 {
            // 检查本地数据，如果存在本地数据，直接返回
            if let result = checkLocalData(maxId) {
                println("加载本地数据...")
                // 从本地加载了数据，直接回调
                let data = StatusesData()
                data.statuses = result
                
                completion(data: data, error: nil)
                return
            }
        }
        
        // 以下是从网络加载数据
        let net = NetworkManager.sharedManager
        if let token = AccessToken.loadAccessToken()?.access_token {
            let params = ["access_token": token,
                "max_id": "\(maxId)"]
            
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
                
                // 保存微博数据
                self.saveStatusData(data?.statuses)
                
                // 如果 maxId > 0，表示是上拉刷新，将 maxId & topId 之间的所有数据的 refresh 状态修改成 1
                self.updateRefreshState(maxId, topId: topId)
                
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
    
    ///  检查本地数据，判断本地是否存在小于 maxId 的连续数据
    ///  如果存在，直接返回本地的数据
    ///  如果不存在，返回 nil，调用方加载网络数据
    class func checkLocalData(maxId: Int) -> [Status]? {
        // 1. 判断 refresh 标记
        let sql = "SELECT count(*) FROM T_Status \n" +
            "WHERE id = (\(maxId) + 1) AND refresh = 1"
        
        if SQLite.sharedSQLite.execCount(sql) == 0 {
            return nil
        }
        
        println("应该加载本地数据")
        // 生成应用程序需要的结果集合直接返回即可！
        // 结果集合中包含微博的数组，同时，需要把分散保存在数据表中的数据，再次整合！
        let resultSQL = "SELECT id, text, source, created_at, reposts_count, \n" +
        "comments_count, attitudes_count, userId, retweetedId FROM T_Status \n" +
        "WHERE id < \(maxId) \n" +
        "ORDER BY id DESC \n" +
        "LIMIT 20"
        
        // 实例化微博数据数组
        var statuses = [Status]()
        
        /// 查询返回结果集合
        let recordSet = SQLite.sharedSQLite.execRecordSet(resultSQL)
        ///  遍历数组，建立目标微博数据数组
        for record in recordSet {
            statuses.append(Status(record: record as! [AnyObject]))
        }
        
        if statuses.count == 0 {
            return nil
        } else {
            return statuses
        }
    }
    
    ///  更新 maxId & topId 之间记录的刷新状态
    class func updateRefreshState(maxId: Int, topId: Int) {
        let sql = "UPDATE T_Status SET refresh = 1 \n" +
            "WHERE id BETWEEN \(maxId) AND \(topId);"
        
        SQLite.sharedSQLite.execSQL(sql)
    }
    
    ///  保存微博数据
    class func saveStatusData(statuses: [Status]?) {
        if statuses == nil {
            return
        }
        
        // 保存数据
        // 0. 开启事务
        // 关于事务，需要注意：
        // 1> BEGIN TRANSACTION & COMMIT TRANSACTION 要配对出现
        // 2> 如果出现错误，可以 ROLLBACK 回滚，注意不要重复 ROLLBACK
        // 3> 在 SQL 操作中，默认都会有一隐含的事务，只是执行一句话，结果就是 true/false
        // 用于批量数据插入的！
        // 不要在多个线程中，同时对数据库进行读写操作！可以创建一个串行队列！把所有数据操作任务，顺序放在队列中执行即可！
        // SQLite 本身的性能已经很好了，大量数据操作不会占用很长的时间！
        SQLite.sharedSQLite.execSQL("BEGIN TRANSACTION")
        
        // 1. 遍历微博数组
        for s in statuses! {
            // 1. 配图记录(保存谁，谁负责)
            if !StatusPictureURL.savePictures(s.id, pictures: s.pic_urls) {
                // 一旦出现错误就“回滚” - 放弃所有的操作
                println("配图记录插入错误")
                SQLite.sharedSQLite.execSQL("ROLLBACK TRANSACTION")
                break
            }
            
            // 2. 用户记录 － 由于不能左右服务器返回的数据
            if s.user != nil {
                if !s.user!.insertDB() {
                    println("插入用户数据错误")
                    SQLite.sharedSQLite.execSQL("ROLLBACK TRANSACTION")
                    break
                }
            }
            
            // 3. 微博记录
            if !s.insertDB() {
                println("插入微博数据错误")
                SQLite.sharedSQLite.execSQL("ROLLBACK TRANSACTION")
                break
            }
            
            // 4. 转发微博的记录（用户/配图）
            if s.retweeted_status != nil {
                // 存在转发微博
                // 保存转发微博
                if !s.retweeted_status!.insertDB() {
                    println("插入转发微博数据错误")
                    SQLite.sharedSQLite.execSQL("ROLLBACK TRANSACTION")
                    break
                }
            }
        }
        
        // 5. 提交事务
        SQLite.sharedSQLite.execSQL("COMMIT TRANSACTION")
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
    
    /// 去掉 href 的来源字符串
    var sourceStr: String {
        return source?.removeHref() ?? ""
    }
    
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
    /// 如果一个属性是只读的，只有 get，没有 set，get 可以省略
    var pictureUrls: [StatusPictureURL]? {
        if retweeted_status != nil {
            return retweeted_status?.pic_urls
        } else {
            return pic_urls
        }
    }
    
    /// 所有大图的 URL － 计算属性
    var largeUrls: [String]? {
        // 可以使用 kvc 直接拿值
        var urls = self.valueForKeyPath("pictureUrls.large_pic") as? NSArray
        return urls as? [String]
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
    
    ///  使用数据库的结果集合，实例化微博数据
    ///  构造函数，实例化并且返回对象
    init(record: [AnyObject]) {
        // id, text, source, created_at, reposts_count, comments_count, attitudes_count, userId, retweetedId
        id = record[0] as! Int
        text = record[1] as? String
        source = record[2] as? String
        created_at = record[3] as? String
        reposts_count = record[4] as! Int
        comments_count = record[5] as! Int
        attitudes_count = record[6] as! Int
        
        // 用户对象
        let userId = record[7] as! Int
        user = UserInfo(pkId: userId)
        
        // 转发微博对象
        let retId = record[8] as! Int
        // 如果有转发数据
        if retId > 0 {
            retweeted_status = Status(pkId: retId)
        }
        
        // 配图数组
        pic_urls = StatusPictureURL.pictureUrls(id)
    }
    
    ///  使用数据库的主键实例化对象
    ///  convenience 不是主构造函数，简化的构造函数，必须调用默认的构造函数
    convenience init(pkId: Int) {
        // 使用主键查询数据库
        let sql = "SELECT id, text, source, created_at, reposts_count, \n" +
        "comments_count, attitudes_count, userId, retweetedId FROM T_Status \n" +
        "WHERE id = \(pkId) "
        
        let record = SQLite.sharedSQLite.execRow(sql)
        
        self.init(record: record!)
    }
    
    // 保存微博数据
    func insertDB() -> Bool {
        // 提示：如果 Xcode 6.3 Bata 2/3 直接写 ?? 会非常非常慢
        let userId = user?.id ?? 0
        let retId = retweeted_status?.id ?? 0
        
        // 判断数据是否已经存在，如果存在就不再插入
        var sql = "SELECT count(*) FROM T_Status WHERE id = \(id);"
        if SQLite.sharedSQLite.execCount(sql) > 0 {
            return true
        }
        
        // 之所以只使用 INSERT，是因为 INSERT AND REPLACE 会在更新数据的时候，直接将 refresh 重新设置为 0
        sql = "INSERT INTO T_Status \n" +
        "(id, text, source, created_at, reposts_count, comments_count, attitudes_count, userId, retweetedId) \n" +
        "VALUES \n" +
        "(\(id), '\(text!)', '\(source!)', '\(created_at!)', \(reposts_count), \(comments_count), \(attitudes_count), \(userId), \(retId));"
        
        return SQLite.sharedSQLite.execSQL(sql)
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
        }
    }
    
    ///  大图 URL
    var large_pic: String?
    
    ///  使用数据库结果集合实例化对象
    init(record: [AnyObject]) {
        thumbnail_pic = record[0] as? String
    }
    
    ///  如果要返回对象的数组，可以使用类函数
    ///  给定一个微博代号，返回改微博代号对应配图数组，0~9张配图
    class func pictureUrls(statusId: Int) -> [StatusPictureURL]? {
        let sql = "SELECT thumbnail_pic FROM T_StatusPic WHERE status_id = \(statusId)"
        let recordSet = SQLite.sharedSQLite.execRecordSet(sql)
        
        // 实例化数组
        var list = [StatusPictureURL]()
        for record in recordSet {
            list.append(StatusPictureURL(record: record as! [AnyObject]))
        }
        
        if list.count == 0 {
            return nil
        } else {
            return list
        }
    }
    
    ///  插入到数据库
    func insertDB(statusId: Int) -> Bool {
        let sql = "INSERT INTO T_StatusPic (statusId, thumbnail_pic) VALUES (\(statusId), '\(thumbnail_pic!)');"
        
        return SQLite.sharedSQLite.execSQL(sql)
    }
    
    ///  将配图数组保存到数据库
    class func savePictures(statusId: Int, pictures: [StatusPictureURL]?) -> Bool {
        
        if pictures == nil {
            // 没有图需要保存，就继续后续的工作
            return true
        }
        
        // 为了避免图片数据会被重复插入，在插入数据前需要先判断一下
        // 判断数据库中是否已经存在 statsId = statusId 图片记录！
        let sql = "SELECT count(*) FROM T_StatusPic WHERE statusId = \(statusId);"
        if SQLite.sharedSQLite.execCount(sql) > 0 {
            return true
        }
        
        // 更新微博图片
        for pic in pictures! {
            // 一旦保存图片失败
            if !pic.insertDB(statusId) {
                // 直接返回
                return false
            }
        }
        return true
    }
}
