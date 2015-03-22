//
//  ComposeTextView.swift
//  HMWeibo04
//
//  Created by apple on 15/3/12.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit

class ComposeTextView: UITextView {

    /// 占位文本 － 注意：懒加载的对象属性，不要使用 weak
    lazy var placeHolderLabel: UILabel? = {
        let l = UILabel()
        l.text = "分享新鲜事..."
        l.font = UIFont.systemFontOfSize(18)
        l.textColor = UIColor.lightGrayColor()
        l.frame = CGRectMake(5, 8, 0, 0)
        // 可以根据文本的内容大小，自动调整
        l.sizeToFit()
        
        return l
        }()
    
    override func awakeFromNib() {
        // 添加占位文本
        addSubview(placeHolderLabel!)
        
        // 文本框默认不支持滚动，设置此属性后，能够滚动！
        alwaysBounceVertical = true
    }
    
    /// 设置文本的表情符号
    func setTextEmoticon(emoticon: Emoticon) {
        // 1. 带图像的属性文本
        var attributeString = EmoteTextAttachment.attributeString(emoticon, height: font.lineHeight)
        
        // 2. 替换 textView 中的属性文本
        // 2.1 可变的属性文本 － 实例化一个 NSMutableAttributedString，每个对象都会有默认属性
        var strM = NSMutableAttributedString(attributedString: attributedText)
        strM.replaceCharactersInRange(selectedRange, withAttributedString: attributeString)
        
        // 2.2 设置完文本属性之后，字体会发生变化 － 定义在 NSAttributedString.h 头文件中
        // 设置整个属性字符串中的文本属性
        let range = NSMakeRange(0, strM.length)
        // 让 可变的属性文本 的字体 和 textView 的保持一致！
        // 设置之后，就不会影响文本框中的文字属性！
        strM.addAttribute(NSFontAttributeName, value: font, range: range)
        
        // 2.3 记录光标位置 location 对应光标的位置
        var location = selectedRange.location
        
        // 2.4 设置 textView 中的文本 － 把图片插入之后，直接替换整个文本
        // 结果会导致光标移动到文本末尾
        attributedText =  strM
        
        // 2.5 重新设置光标位置
        selectedRange = NSMakeRange(location + 1, 0)
    }

    /// 返回文本框中完成文字 - 将表情图片转换成表情符号
    func fullText() -> String {
        var result = String()
        let textRange = NSMakeRange(0, attributedText.length)
        
        attributedText.enumerateAttributesInRange(textRange, options: NSAttributedStringEnumerationOptions.allZeros, usingBlock: { (dict, range, _) -> Void in
            
            if let attachment = dict["NSAttachment"] as? EmoteTextAttachment {
                // 图片
                result += attachment.emoteString!
            } else {
                result += (self.attributedText.string as NSString).substringWithRange(range)
            }
        })
        println("微博文本：\(result)")
        
        return result
    }
}
