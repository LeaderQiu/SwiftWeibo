//
//  MainTabBarController.swift
//  HMWeibo04
//
//  Created by apple on 15/3/5.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    // 不能起 tabBar 的名字
    @IBOutlet weak var mainTabBar: MainTabBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 使用代码添加视图控制器
        addControllers()
        
        // 定义回调 - Swift 中的闭包同样会对外部变量进行强引用
        // 提示：weak 变量必须是 var，不能使用 let
        // 在 swift 中判断闭包的循环引用和 oc 中几乎是一样的，使用 deinit
        weak var weakSelf = self
        mainTabBar.composedButtonClicked = {
            println("hello")
            // modal 撰写微博 视图控制器
            let sb = UIStoryboard(name: "Compose", bundle: nil)
            
            weakSelf!.presentViewController(sb.instantiateInitialViewController() as! UIViewController, animated: true, completion: nil)
        }
    }
    
    ///  deinit 和 OC 中的 dealloc 作用是类似的
    deinit {
        println("没有循环引用")
    }
    
    ///  添加子控制器
    func addControllers() {
        addchildController("Home", "首页", "tabbar_home", "tabbar_home_highlighted")
        addchildController("Message", "消息", "tabbar_message_center", "tabbar_message_center_highlighted")
        addchildController("Discover", "发现", "tabbar_discover", "tabbar_discover_highlighted")
        addchildController("Profile", "我", "tabbar_profile", "tabbar_profile_highlighted")
    }
    
    ///  添加视图控制器
    ///
    ///  :param: name      sb name
    ///  :param: title     标题
    ///  :param: imageName 图像名称
    ///  :param: highlight 高亮名称
    func addchildController(name: String, _ title: String, _ imageName: String, _ highlight: String) {
        let sb = UIStoryboard(name: name, bundle: nil)
        let vc = sb.instantiateInitialViewController() as! UINavigationController
        // 添加图标&文字
        vc.tabBarItem.image = UIImage(named: imageName)
        vc.tabBarItem.selectedImage = UIImage(named: highlight)?.imageWithRenderingMode(.AlwaysOriginal)
        
        vc.title = title
        
        // 设置文字颜色，在 UIKit 框架中，大概有 7~9 个头文件是以 NS 开头的，都是和文本相关的
        // NSAttributedString 中定义的文本属性，主要用在"图文混排"
        vc.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.orangeColor()], forState: UIControlState.Selected)
        
        self.addChildViewController(vc)
    }
}
