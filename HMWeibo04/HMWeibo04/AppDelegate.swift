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
        
        
        if let token = AccessToken.loadAccessToken() {
            println(token.debugDescription)
            println(token.uid)
        }
        
        // 实例化对象的时候，()就是调用默认的构造函数
        let net = SimpleNetwork()
        
        let urls = ["http://ww1.sinaimg.cn/thumbnail/62c13fbagw1epuww0k4xgj20c8552b29.jpg",
        "http://ww3.sinaimg.cn/thumbnail/e362b134jw1epuxb47zoyj20dw0ku421.jpg",
        "http://ww1.sinaimg.cn/thumbnail/e362b134jw1epuxbaym1sj20ku0dwgpu.jpg",
        "http://ww2.sinaimg.cn/thumbnail/e362b134jw1epuxbdhirmj20dw0kuae8.jpg"]
        
        println(net.downloadImages(urls, { (result, error) -> () in
            println("OK")
        }))
     
        // 设置 nav 按钮的外观
        setNavAppearance()
        
        return true
    }
    
    ///  设置按钮的 tintColor
    func setNavAppearance() {
        // 提示：关于外观的设置，应该在 appDelegate 中，程序一启动就设置
        // 一经设置，全局有效
        // 有一个比较常见的外观设置：UISwitch
        UINavigationBar.appearance().tintColor = UIColor.orangeColor()
    }
}

