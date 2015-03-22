//
//  HMRefreshControl.swift
//  HMWeibo04
//
//  Created by apple on 15/3/9.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit

/**
    如果下拉幅度不够，只是显示控件，不会真正刷新数据
    如果下拉幅度够大，会自动进入刷新状态，控件不会自动消失

    下一步的目标：实际测试中发现，如果想要更改内部视图的显示，首先需要解决一个问题：
    - 需要知道用户到底向下拉了多少！
    思路：KVO 可以观察内部属性的变化
*/
class HMRefreshControl: UIRefreshControl {

    lazy var refreshView: RefreshView = {
        return RefreshView.refreshView(isLoading: false)
    }()
    
    ///  提示：refresh control 中不要重写 layoutSubviews，本方法调用非常频繁
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        
//        println("\(__FUNCTION__)")
//    }
    
    /**
        视图的生命周期函数
    
        1. willMoveToSuperview - 与界面无关的
        2. didMoveToSuperview - 与界面无关的
        3. awakeFromNib - 从 xib 加载子视图内部细节，视图的层次结构
        4. willMoveToWindow - 就要显示了
        5. didMoveToWindow - 已经显示了
        6. layoutSubviews - 布局
    */
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        
        println("\(__FUNCTION__)")
    }
    
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        
        println("\(__FUNCTION__) \(self.frame)")
        
        // 设置刷新视图的大小
        refreshView.frame = self.bounds
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        println("\(__FUNCTION__)")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()

        println("\(__FUNCTION__) \(self.frame)")
    }
    
    // MARK: - KVO
    override func awakeFromNib() {
        println("!!!!!!!! \(__FUNCTION__) \(self.frame)")
        self.addSubview(refreshView)
        
        // 添加观察者，观察控件自身位置的变化
        self.addObserver(self, forKeyPath: "frame", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    deinit {
        println("刷新控件 88")
        
        // 销毁观察者
        self.removeObserver(self, forKeyPath: "frame")
    }
    
    /**
        观察结果
        1. 向下拉：y 值，逐渐变小
        2. 当 y 值足够小的时候，自动进入刷新状态
        3. 当表格向上滚动，刷新控件是一只存在的，不会被销毁，而且位置会和表格一起运动
    */
    // 正在显示加载的动画效果
    var isLoading = false
    /// 旋转提示图标标记
    var isRotateTip = false
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        
//        println("\(change) \(self.frame)")
        if self.frame.origin.y > 0 {
            return
        }
        
        // 正在刷新
        if refreshing && !isLoading {
            // 显示记载视图，同时播放旋转动画效果
            refreshView.showLoading()
            
            isLoading = true
            
            return
        }
        
        // 在真正开发中，要反复的观察，确认思路！千万不能着急！
        // 因为 kvo 观察的时候，数值变化非常频繁！
        if self.frame.origin.y < -50 && !isRotateTip {
//            println("该转身了")
            isRotateTip = true
            refreshView.rotateTipIcon(isRotateTip)
        } else if self.frame.origin.y > -50 && isRotateTip {
//            println("转回去")
            isRotateTip = false
            refreshView.rotateTipIcon(isRotateTip)
        }
    }
    
    override func endRefreshing() {
        
        // 调用父类方法
        super.endRefreshing()
        
        // 停止动画
        refreshView.stopLoading()
        
        // 修改正在加载标记
        isLoading = false
    }
}

///  刷新控件内部视图
class RefreshView: UIView {
    
    /// 从 xib 加载刷新视图
    class func refreshView(isLoading: Bool = false) -> RefreshView {
        let v = NSBundle.mainBundle().loadNibNamed("HMRefreshView", owner: nil, options: nil).last as! RefreshView
        v.tipView.hidden = isLoading
        v.loadingView.hidden = !isLoading
        
        return v
    }
    
    ///  提示视图
    @IBOutlet weak var tipView: UIView!
    ///  提示图标
    @IBOutlet weak var tipIcon: UIImageView!
    ///  加载视图
    @IBOutlet weak var loadingView: UIView!
    ///  加载图标
    @IBOutlet weak var loadingIcon: UIImageView!
 
    ///  显示加载状态，转轮
    func showLoading() {
        tipView.hidden = true
        loadingView.hidden = false
        
        // 添加动画
        loadingAnimation()
    }
    
    // 加载动画
    /**
        核心动画 - 属性动画 => 
        - 基础动画： fromValue toValue
        - 关键帧动画：values, path
        * 将动画添加到图层
    */
    func loadingAnimation() {
        let anim = CABasicAnimation(keyPath: "transform.rotation")
        
        anim.toValue = 2 * M_PI
        // 重复次数 OC MAX_FLOAT
        anim.repeatCount = MAXFLOAT
        // 转一圈的时间
        anim.duration = 0.5
        
        // 将动画添加到涂层
        loadingIcon.layer.addAnimation(anim, forKey: nil)
    }
 
    ///  停止加载动画
    func stopLoading() {
        // 将动画从涂层中删除
        loadingIcon.layer.removeAllAnimations()
        
        // 恢复视图的显示
        tipView.hidden = false
        loadingView.hidden = true
    }
    
    ///  旋转提示图标
    func rotateTipIcon(clockWise: Bool) {
        
        // 在 iOS 中旋转都是就近原则，如果转半圈，会找近路
        var angel = CGFloat(M_PI + 0.01)
        if clockWise {
            angel = CGFloat(M_PI - 0.01)
        }
        
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            // 旋转提示图标 180
            self.tipIcon.transform = CGAffineTransformRotate(self.tipIcon.transform, angel)
        })
    }
    
    // MARK: - 上拉刷新部分代码
    // parentView 默认是强引用，会对视图控制器中的tableView进行强引用
    // OC 中设置代理，代理必须要使用 weak
//    var parentView: UITableView?
    weak var parentView: UITableView?
    
    // 给 parentView 添加观察
    func addPullupOberserver(parentView: UITableView, pullupLoadData: ()->()) {

        // 1. 记录要观察的表格视图
        self.parentView = parentView
        
        // 2. 记录上拉加载数据的闭包
        self.pullupLoadData = pullupLoadData
        
        self.parentView?.addObserver(self, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    // KVO 的代码
    /***
        使用观察者的时候，被观察对象释放之前，一定要先注销观察者！
    */
    deinit {
        println("刷新视图 88")
        // 注意** 不一定写在 deinit 中就一定保险的
        // EXC_BAD_INSTRUCTION OC 中的野指针！
//        parentView!.removeObserver(self, forKeyPath: "contentOffset")
    }
    
    // 上拉加载数据标记
    var isPullupLoading = false
    // 上拉加载数据闭包
    var pullupLoadData: (()->())?
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        
        // 1. 如果在 tableView 的顶部，不进行刷新，直接返回
        if self.frame.origin.y == 0 {
            return
        }
        
        if (parentView!.bounds.size.height + parentView!.contentOffset.y) > CGRectGetMaxY(self.frame) {
            // 2. 保证上拉加载数据的判断只有一次是有效的
            if !isPullupLoading {
                println("上拉加载数据！！！")
                isPullupLoading = true
                
                // 播放转轮动画
                showLoading()
                
                // 3. 判断闭包是否存在，如果存在，执行闭包
                if pullupLoadData != nil {
                    pullupLoadData!()
                }
            }
        }
    }
    
    /// 上拉刷新完成
    func pullupFinished() {
        // 重新设置刷新视图的属性
        isPullupLoading = false
        
        // 停止动画
        stopLoading()
    }
}
