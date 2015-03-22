//
//  MainNavViewController.swift
//  HMWeibo04
//
//  Created by apple on 15/3/5.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit

///  这个现在已经没用了
class MainNavViewController: UINavigationController {

    // cmd+shift+o
    /**
        initialize 是在类第一次被调用时会执行
        函数内部的代码在执行时，是线程安全的
    
        问题：
        1> 一旦设置了外观，再返回后，外部其他的 nav 的按钮颜色同样会变化！
        2> 使用 setTitleTextAttributes 设置字体颜色后，disable状态的按钮颜色同样会发生变化
    */
    override class func initialize() {
        println(__FUNCTION__)
        
//        let bar = UINavigationBar.appearance()
//        bar.tintColor = UIColor.orangeColor()
    }
    
    // 设置 barButtonItem 外观
    func setButtonItemApp() {
        // 设置 UIBarButtonItem 按钮的统一外观，外观一旦设置，全局有效
        let item = UIBarButtonItem.appearance()
        
        // 设置文本颜色
        item.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.orangeColor()], forState: UIControlState.Normal)
    }
}
