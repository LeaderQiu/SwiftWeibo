//
//  Emoticons.swift
//  HMWeibo04
//
//  Created by apple on 15/3/12.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import Foundation

/// 表情符号数组单例，专供查询使用
class EmoticonList {
    
    /// 单例
    private static let instance = EmoticonList()
    class var sharedEmoticonList: EmoticonList  {
        return instance
    }
    
    /// 所有自定义表情的大数组，便于查询
    var emoticons: [Emoticon]
    
    init () {
        // 实例化表情数组
        emoticons = [Emoticon]()
        
        // 填充数据
        // 1. 加载分组数据中的表情
        let sections = EmoticonsSection.loadEmoticons()
        
        // 2. 合并数组（提示：可以把 emoji 去掉）
        for sec in sections {
            emoticons += sec.emoticons
        }
    }
}

/// 表情符号分组 -> 专门给键盘服务的
class EmoticonsSection {
    /// 平时定义对象属性的时候，都是使用可选类型 ?
    /// 原因：没有构造函数给对象属性设置初始数值
    /// 分组名称
    var name: String
    /// 类型
    var type: String
    /// 路径
    var path: String
    /// 表情符号的数组(每一个 section中应该包含21个表情符号，界面处理是最方便的)
    /// 其中21个表情符号中，最后一个删除(就不能使用plist中的数据)
    var emoticons: [Emoticon]
    
    /// 使用字典实例化对象
    /// 构造函数，能够给对象直接设置初始数值，凡事设置过的属性，都可以是必选项
    /// 在构造函数中，不需要 super，直接给属性分配空间&初始化
    init(dict: NSDictionary) {
        name = dict["emoticon_group_name"] as! String
        type = dict["emoticon_group_type"] as! String
        path = dict["emoticon_group_path"] as! String
        emoticons = [Emoticon]()
    }
    
    /// 加载表情符号分组数据
    class func loadEmoticons() -> [EmoticonsSection] {
        
        // 1. 路径
        let path = NSBundle.mainBundle().bundlePath.stringByAppendingPathComponent("Emoticons/emoticons.plist")
        var array = NSArray(contentsOfFile: path)!
        
        // 1.1 对数组进行排序，字段是 type
        array = array.sortedArrayUsingComparator { (dict1, dict2) -> NSComparisonResult in
            let type1 = dict1["emoticon_group_type"] as! String
            let type2 = dict2["emoticon_group_type"] as! String
            
            // compare 函数可以比较非常多的 OC 的数据对象，NSString, NSNumber，NSDate...
            return type1.compare(type2)
        }
        
        // 2. 遍历数组
        var result = [EmoticonsSection]()
        for dict in array as! [NSDictionary] {
            // 进入 group_path 对应的目录进一步加载数据
            result += loadEmoticons(dict)
        }
        
        return result
    }
    
    /// 使用 dict 加载 group_path 对应的表情符号数组
    class func loadEmoticons(dict: NSDictionary) -> [EmoticonsSection] {
        // 1. 根据 dict 中的 group_path 加载不同目录中的 info.plist
        let group_path = dict["emoticon_group_path"] as! String
        let path = NSBundle.mainBundle().bundlePath.stringByAppendingPathComponent("Emoticons/\(group_path)/info.plist")
        
        // 2. 加载 info.plist
        var infoDict = NSDictionary(contentsOfFile: path)!
        
        // 3. 从 infoDict 的 emoticon_group_emoticons 中提取表情符号数组
        let list = infoDict["emoticon_group_emoticons"] as! NSArray
        var result = loadEmoticons(list, dict: dict)
        
        return result
    }
    
    /// 从 emoticon_group_emoticons 返回表情数组的数组，每一个数组 都 包含 21 个表情(最后一个是空的)
    /// 这是真正创建数据的函数！
    class func loadEmoticons(list: NSArray, dict: NSDictionary) -> [EmoticonsSection] {
        
        // 生成数组，每20个就建立一个 EmoticonsSection 对象
        let emoticonCount = 20
        // 计算总共需要建立多少个对象
        let objCount = (list.count - 1) / emoticonCount + 1
        
        println("对象个数 \(objCount)")
        // 循环创建对象，依次填充表情数组
        var result = [EmoticonsSection]()
        
        for i in 0..<objCount {
            // 1. 创建对象（路径就已经存在了）
            var emoticon = EmoticonsSection(dict: dict)
            
            // 2. 填充对象内部的表情符号数据
            // 遍历数组 0~19, 20~39, 40~69....
            println("---")
            for count in 0..<20 {
                // 计算数组下标
                let j = count + i * emoticonCount
                
                // 判断对应 j 下标，在数组中是否存在
                var dict: NSDictionary? = nil
                
                if j < list.count {
                    // 数组中有内容
                    // 实例化表情符号对象
                    dict = list[j] as? NSDictionary
                }
                
                let em = Emoticon(dict: dict, path: emoticon.path)
                emoticon.emoticons.append(em)
            }
            // 再添加一项，给末尾的删除按钮，需要再实例化一个空的表情对象
            let em = Emoticon(dict: nil, path: nil)
            em.isDeleteButton = true
            emoticon.emoticons.append(em)
            
            // 3. 将对象添加到数组
            result.append(emoticon)
        }
        
        return result
    }
}

/// 表情符号类
class Emoticon {
    /// emoji 的16进制字符串
    var code: String?
    /// emoji 字符串
    var emoji: String?

    /// 类型
    var type: String?
    /// 表情符号的文本 - 发送给服务器的文本
    var chs: String?
    /// 表情符号的图片 - 本地做图文混排使用的图片
    var png: String?
    /// 图像的完整路径
    var imagePath: String?
    /// 是否是删除按钮
    var isDeleteButton = false
    
    init(dict: NSDictionary?, path: String?) {
        code = dict?["code"] as? String
        type = dict?["type"] as? String
        chs = dict?["chs"] as? String
        png = dict?["png"] as? String
        
        if path != nil && png != nil {
            imagePath = NSBundle.mainBundle().bundlePath.stringByAppendingPathComponent("Emoticons/\(path!)/\(png!)")
        }
        
        // 计算 emoji 
        if code != nil {
            let scanner = NSScanner(string: code!)
            // 提示：如果要传递指针，不能使用 let，var 才能修改数值
            var value: UInt32 = 0
            scanner.scanHexInt(&value)
            emoji = "\(Character(UnicodeScalar(value)))"
        }
    }
}
