//
//  ComposeViewController.swift
//  HMWeibo04
//
//  Created by apple on 15/3/5.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit

class ComposeViewController: UIViewController, UITextViewDelegate {

    /// 发送按钮
    @IBOutlet weak var sendButton: UIBarButtonItem!
    
    @IBOutlet weak var toolBarBottomConstraint: NSLayoutConstraint!

    /// 文本框
    @IBOutlet weak var textView: ComposeTextView!
    
    ///  取消
    @IBAction func cancel(sender: UIBarButtonItem) {
        // 关闭键盘
        self.textView.resignFirstResponder()
        
        // 关闭视图控制器
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    /// 发送微博
    @IBAction func sendStatus(sender: UIBarButtonItem) {
        let urlString = "https://api.weibo.com/2/statuses/update.json"
        
        if let token = AccessToken.loadAccessToken()?.access_token {
            let params = ["access_token": token,
                "status": textView.fullText()]
            
            let net = NetworkManager.sharedManager
            // 重点提示：params中一定都要确保有值，否则会提示 .POST 不正确！
            net.requestJSON(.POST, urlString, params) { (result, error) -> () in
                SVProgressHUD.showInfoWithStatus("微博发送成功")
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 注册通知
        registerNotification()
        
        // 添加子视图控制器 － 可以保证响应者链条正常传递
        self.addChildViewController(emoticonsVC!)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // 设置文本框的默认焦点
        textView.becomeFirstResponder()
    }
    
    /// 注册键盘通知
    func registerNotification() {
        // 添加观察者，监听键盘框架的变化
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardFrameChanged:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardFrameChanged:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    /// 键盘变化监听方法
    func keyboardFrameChanged(notification: NSNotification) {
//        println(notification)
        
        // 不监听键盘关闭，就不会跳动，监听的时候，就会跳动
        // 关闭键盘的时候，不使用动画
        if notification.name == UIKeyboardWillChangeFrameNotification {
            let rect = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let height = rect.size.height
            
            let duration = (notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            
            toolBarBottomConstraint.constant = height
            
            UIView.animateWithDuration(duration) {
                self.view.layoutIfNeeded()
            }
        } else {
            toolBarBottomConstraint.constant = 0
        }
    }
    
    // MARK: - 选择表情部分代码
    /// 表情视图控制器
    lazy var emoticonsVC: EmoticonsViewController? = {
        let sb = UIStoryboard(name: "Emoticons", bundle: nil)
        let vc = sb.instantiateInitialViewController() as? EmoticonsViewController
        
        // 1. 设置代理
        vc?.delegate = self
        
        return vc
    }()
    
    /// 选择表情
    @IBAction func selectEmote() {
        
        // inputView == nil 就使用的是系统的键盘
        println(textView.inputView)
        
        // 关闭键盘
        textView.resignFirstResponder()
        
        // 更换 textView 的输入视图[键盘]
        // 如果要更换文本框的输入视图，需要注意当前文本框不能处于输入状态
//        let v = UIView(frame: CGRectMake(0, 0, 320, 216))
//        v.backgroundColor = UIColor.redColor()
        
        if textView.inputView == nil {
            textView.inputView = emoticonsVC?.view
        } else {
            textView.inputView = nil
        }
        
        // 开启键盘
        textView.becomeFirstResponder()
    }
}

// 2. 遵守协议(通过 extension)并且实现方法！
extension ComposeViewController: EmoticonsViewControllerDelegate {
 
    func emoticonsViewControllerDidSelectEmoticon(vc: EmoticonsViewController, emoticon: Emoticon) {
        
        // 判断是否是删除按钮
        if emoticon.isDeleteButton {
            // 删除文字
            textView.deleteBackward()
            
            return
        }
        
        var str: String?
        if emoticon.chs != nil {
            str = emoticon.chs!
        } else if emoticon.emoji != nil {
            str = emoticon.emoji
        }
        if str == nil {
            return
        }
        
        // 手动调用代理方法 - 是否能够插入文本
        if textView(textView, shouldChangeTextInRange: textView.selectedRange, replacementText: str!) {
            // 可以替换文本
            // 设置文本
            if emoticon.chs != nil {
                // 设置表情 attributeString，没有修改 text，以下两个代理方法，都不会被调用
                textView.setTextEmoticon(emoticon)
                
                // 手动调用 didChage 方法
                textViewDidChange(textView)
            } else if emoticon.emoji != nil {
                // 应该在用户光标位置“插入”表情文本
                // 会调用 didChange - text 会变化
                // 不会调用 shouldChangeTextInRange - 判断是否需要修改 range 中的内容
                textView.replaceRange(textView.selectedTextRange!, withText: emoticon.emoji!)
            }
        }
    }
}

/// UITextView 的扩展
extension ComposeViewController: UITextViewDelegate {
    /// 将要使用 replacementText 添加到 textView 的 range 位置
    /// 能够在用户输入之前进行判断
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        // 删除键或者其他的功能键如何判断？
        if text.isEmpty {
            println("是删除吗？")
            return true
        }
        
        // 在 textView 控件中，没有代理方法监听回车键！
        // 以下代码是在 textView 中拦截回车键的办法
        if text == "\n" {
            println("回车键")
        }
        
        // 微博文字通常限制 140 个字
        // lengthOfBytesUsingEncoding 返回的是 UTF8 编码的字节长度！
        // NSString.length 返回的字符的个数
        // 注意：text 当前并没有表情符号的内容
        let len1 = (self.textView.fullText() as NSString).length
        let len2 = (text as NSString).length
//        println("\(text) --- \(len2)")
//        println("\(textView.text) --- \(len2)")
        
        if (len1 + len2) > 140 {
            return false
        }
        
        return true
    }
    
    /// 文本完成变化的事件
    func textViewDidChange(textView: UITextView) {
        let fullText = self.textView.fullText()
        
        self.textView.placeHolderLabel!.hidden = !fullText.isEmpty
        sendButton.enabled = !fullText.isEmpty
    }
    
    /// 滚动视图开始被拖拽
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        textView.resignFirstResponder()
    }
}
