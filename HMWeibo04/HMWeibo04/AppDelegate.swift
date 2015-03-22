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
        
        // 打开数据库
        SQLite.sharedSQLite.openDatabase("readme.db")
        
        // 测试发布代图片的微博
        uploadPicture()
        
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
    
    func uploadPicture() {
        let urlString = "https://upload.api.weibo.com/2/statuses/upload.json"
        let token = AccessToken.loadAccessToken()
        
        let params = ["access_token": token!.access_token!, "status": "测试一下"]
        let image = UIImage(named: "compose_photo_preview_right")
        let data = UIImagePNGRepresentation(image)
        
        NetworkManager.sharedManager.postUpload(urlString, params: params, fieldName: "pic", dataList: [data], filenames: ["oooo"]) { (result, error) -> () in
            
            println(NSThread.currentThread())
        }
    }
    
    ///  测试上拉刷新数据的代码
    func demoLoadData() {
        // 加载数据测试代码 － 第一次刷新，都是从服务器加载数据！
        StatusesData.loadStatus(maxId: 0, topId: 0) { (data, error) -> () in
            // 第一次加载的数据
            if let statuses = data?.statuses {
                // 模拟上拉刷新
                // 取出最后一条记录中的 id，id -1 -> maxId
                let mId = statuses.last!.id
                let tId = statuses.first!.id
                println("maxId \(mId) ---- topId \(tId)")
                
                // 上拉刷新
                StatusesData.loadStatus(maxId: (mId - 1), topId: tId, completion: { (data, error) -> () in
                    println("第一次上拉刷新结束")
                    
                    // 再一次加载的数据
                    if let statuses = data?.statuses {
                        // 模拟上拉刷新
                        // 取出最后一条记录中的 id，id -1 -> maxId
                        let mId = statuses.last!.id
                        let tId = statuses.first!.id
                        println("2222 maxId \(mId) ---- topId \(tId)")
                        
                        // 上拉刷新
                        StatusesData.loadStatus(maxId: (mId - 1), topId: tId, completion: { (data, error) -> () in
                            println("第二次上拉刷新结束")
                        })
                    }
                })
            }
        }
    }
    
    ///  显示主界面
    func showMainInterface() {
        // 设置 nav 按钮的外观
        // TODO : 如果重置模拟器，会发现导航栏按钮是蓝色的！
        setNavAppearance()
        
        // 通知在不需要的时候，要及时销毁
        NSNotificationCenter.defaultCenter().removeObserver(self, name: WB_Login_Successed_Notification, object: nil)
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        window!.rootViewController = sb.instantiateInitialViewController() as? UIViewController
    }
    
    ///  设置按钮的 tintColor
    func setNavAppearance() {
        // 提示：关于外观的设置，应该在 appDelegate 中，程序一启动就设置
        // 一经设置，全局有效
        // 有一个比较常见的外观设置：UISwitch
        UINavigationBar.appearance().tintColor = UIColor.orangeColor()
    }
}

