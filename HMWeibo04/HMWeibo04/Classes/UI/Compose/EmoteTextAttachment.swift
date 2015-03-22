//
//  EmoteTextAttachment.swift
//  HMWeibo04
//
//  Created by apple on 15/3/12.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit

class EmoteTextAttachment: NSTextAttachment {
    // 表情对应的文本符号
    var emoteString: String?
    
    /// 返回一个 属性字符串
    class func attributeString(emoticon: Emoticon, height: CGFloat) -> NSAttributedString {
        var attachment = EmoteTextAttachment()
        attachment.image = UIImage(contentsOfFile: emoticon.imagePath!)
        attachment.emoteString = emoticon.chs
        
        // 设置高度
        attachment.bounds = CGRectMake(0, -4, height, height)
        
        // 2. 带图像的属性文本
        return NSAttributedString(attachment: attachment)
    }
}
