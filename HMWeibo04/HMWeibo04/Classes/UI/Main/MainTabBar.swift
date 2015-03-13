//
//  MainTabBar.swift
//  HMWeibo04
//
//  Created by apple on 15/3/5.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit

class MainTabBar: UITabBar {

    ///  点击撰写微博按钮回调(闭包) -> (括号内部是闭包函数的类型 (参数)->(返回值))
    var composedButtonClicked: (()->())?
    
    override func awakeFromNib() {
        self.addSubview(composeBtn!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setButtonsFrame()
    }
    
    ///  设置按钮的位置，水平均分显示"五"个按钮
    func setButtonsFrame() {
        // 1. 计算基本属性
        let w = self.bounds.size.width / CGFloat(buttonCount)
        let h = self.bounds.size.height

        var index = 0
        // 2. 遍历子视图，提示：UITabBarButton属于私有API，在程序中如果直接使用私有 API，通常不能上架
        // ** 在 swift 中遍历子视图一定要指定子视图的类型
        // ** 所有的基本数字类型在计算时，类型一定要匹配！
        for view in self.subviews as! [UIView] {
            // 判断子视图是否是控件，UITabBarButton是继承自 UIControl
            if view is UIControl && !(view is UIButton) {
                let r = CGRectMake(CGFloat(index) * w, 0, w, h)
                
                view.frame = r
                
                index++
                if index == 2 {
                    index++
                }
            }
        }
        
        // 3. 设置加号按钮的位置
        composeBtn!.frame = CGRectMake(0, 0, w, h)
        composeBtn!.center = CGPointMake(self.center.x, h * 0.5)
    }
    
    /// 按钮总数
    let buttonCount = 5
    
    /// 创建撰写微博按钮
    lazy var composeBtn: UIButton? = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "tabbar_compose_icon_add"), forState: UIControlState.Normal)
        btn.setImage(UIImage(named: "tabbar_compose_icon_add_highlighted"), forState: UIControlState.Highlighted)
        btn.setBackgroundImage(UIImage(named: "tabbar_compose_button"), forState: UIControlState.Normal)
        btn.setBackgroundImage(UIImage(named: "tabbar_compose_button_highlighted"), forState: UIControlState.Highlighted)
        
        // 添加按钮的监听方法
        btn.addTarget(self, action: "clickCompose", forControlEvents: .TouchUpInside)
        
        return btn
        
    }()
    
    func clickCompose() {
        println("come here")
        // 判断闭包是否被设置数值
        if composedButtonClicked != nil {
            // 执行回调方法
            composedButtonClicked!()
        }
    }
}
