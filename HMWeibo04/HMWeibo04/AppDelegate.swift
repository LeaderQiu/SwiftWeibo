//
//  AppDelegate.swift
//  HMWeibo04
//
//  Created by apple on 15/3/2.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        println("hello".md5)
        
        // 检查沙盒中是否已经保存的 token
        // 如果已经存在 token，应该直接显示主界面
        if let token = AccessToken.loadAccessToken() {
            println(token.debugDescription)
            println(token.uid)
            
            showMainInterface()
        } else {
            // 添加通知监听，监听用户登录成功
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "showMainInterface", name: WB_Login_Successed_Notification, object: nil)
        }
        
        return true
    }
    
    ///  显示主界面
    func showMainInterface() {
        // 通知在不需要的时候，要及时销毁
        NSNotificationCenter.defaultCenter().removeObserver(self, name: WB_Login_Successed_Notification, object: nil)
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        window!.rootViewController = sb.instantiateInitialViewController() as? UIViewController
        
        // 设置 nav 按钮的外观
        setNavAppearance()
    }
    
    ///  设置按钮的 tintColor
    func setNavAppearance() {
        // 提示：关于外观的设置，应该在 appDelegate 中，程序一启动就设置
        // 一经设置，全局有效
        // 有一个比较常见的外观设置：UISwitch
        UINavigationBar.appearance().tintColor = UIColor.orangeColor()
    }
}

