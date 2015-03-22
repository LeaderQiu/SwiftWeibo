//
//  HomeViewController.swift
//  HMWeibo04
//
//  Created by apple on 15/3/5.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit

class HomeViewController: UITableViewController {

    /// 微博数据 - statuses 中维护了当前 tableView 显示的所有数据
    /// statuses 中的所有数据都是连续的！
    var statusData: StatusesData?
    /// 行高缓存
    lazy var rowHeightCache: NSCache? = {
        return NSCache()
    }()
    
    /// 上拉加载视图懒加载
    lazy var pullupView: RefreshView = {
        return RefreshView.refreshView(isLoading: true)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPullupView()
        
        loadData()
    }
    
    /// 设置上拉加载数据视图
    func setupPullupView() {
        // 添加 tableView 的footer，tableView会对 pullupView 强引用
        tableView.tableFooterView = pullupView
        
        // 让上拉刷新视图 监听 tableView 的 contentOffset 动作
        weak var weakSelf = self
        pullupView.addPullupOberserver(tableView) {
//            println("上拉加载数据啦～～～～～")
            
            // 获取到 maxId
            if let statuses = weakSelf?.statusData?.statuses {
                let maxId = statuses.last!.id
                let topId = statuses.first!.id
                
                weakSelf?.loadData(maxId - 1, topId: topId)
            }
        }
    }
    
    deinit {
        println("主页视图控制器被释放!!!!!!")
        
        // 主动释放加载刷新视图对tableView的观察
        tableView.removeObserver(pullupView, forKeyPath: "contentOffset")
    }

    ///  加载微博数据
    /**
        Refresh控件高度是 60 点
    */
    @IBAction func loadData() {
        loadData(0, topId: 0)
    }
    
    func loadData(maxId: Int, topId: Int) {
        // 主动开始加载数据
        refreshControl?.beginRefreshing()
        
        // 之所以设置成 weak 是为了避免循环引用，但是 self 的对象可能会随时被销毁！
        // 需要注意一个细节，一旦某种原因，self 被释放掉，内部的 weakSelf 再执行就会崩溃！
        // 推荐写法：weakSelf?，一旦 self 被释放，不会影响程序的执行！
        // git 一定要在"阶段性工作"告一段落后提交！
        weak var weakSelf = self
        
        // 要修改刷新数据
        StatusesData.loadStatus(maxId: maxId, topId: topId) { (data, error) -> () in
            // 隐藏刷新控件
            weakSelf?.refreshControl?.endRefreshing()
            
            if error != nil {
                println(error)
                SVProgressHUD.showInfoWithStatus("你的网络不给力")
                return
            }
            if data != nil {
                // 刷新新数据
                if maxId == 0 {
                    // 刷新表格数据
                    weakSelf?.statusData = data
                    weakSelf?.tableView.reloadData()
                } else {
                    // 上拉刷新
                    println("加载到了新数据！")
                    // 拼接数据，数组的拼接
                    let list = weakSelf!.statusData!.statuses! + data!.statuses!
                    weakSelf!.statusData?.statuses = list
                    
                    weakSelf?.tableView.reloadData()
                    
                    // 重新设置刷新视图的属性
                    weakSelf?.pullupView.pullupFinished()
                }
            }
        }
    }
}

///  表格数据源 & 代理扩展
extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.statusData?.statuses?.count ?? 0
    }
    
    ///  根据indexPath 返回微博数据&可重用标识符
    func cellInfo(indexPath: NSIndexPath) -> (status: Status, cellId: String) {
        let status = self.statusData!.statuses![indexPath.row]
        let cellId = StatusCell.cellIdentifier(status)
        
        return (status, cellId)
    }
    
    ///  准备表格的cell
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // 提取cell信息
        let info = cellInfo(indexPath)
        
        let cell = tableView.dequeueReusableCellWithIdentifier(info.cellId, forIndexPath: indexPath) as! StatusCell
        
        // 判断表格的闭包是否被设置
        if cell.photoDidSelected == nil {
            // 设置闭包
            weak var weakSelf = self
            cell.photoDidSelected = { (status: Status, photoIndex: Int)->() in
                println("\(status.text) \(photoIndex)")
                // 将数据传递给照片浏览器视图控制器
                // 使用类方法调用，不需要知道视图控制器太多的内部细节
                let vc = PhotoBrowserViewController.photoBrowserViewController()
                
                vc.urls = status.largeUrls
                vc.selectedIndex = photoIndex
                
                weakSelf?.presentViewController(vc, animated: true, completion: nil)
            }
        }
        
        cell.status = info.status
        
        return cell
    }
    
    // 行高的处理，即使有预估行高，仍然会计算三次！只计算一次！
    /**
        缓存：NSCache 
        1. 使用和 NSDictionary 非常类似
        2. 线程安全的
        3. 如果内存紧张，会自动释放
    
        要缓存的信息：行高，什么来做 key? － 微博 id
        ** 使用 NSCache
            * 如果使用 NSCache，需要保证，对象即使被释放，仍然能够再次创建！
            * 使用 NSCache 一定要注意 key，对于表格应用，要尽量不要用 indexPath
                一旦下拉刷新或者上拉刷新，所有的数据需要重新计算！
    */
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        // 提取cell信息
        let info = cellInfo(indexPath)
        
        // 判断是否已经缓存了行高
        if let h = rowHeightCache?.objectForKey("\(info.status.id)") as? NSNumber {
            println("从缓存返回 \(h)")
            return CGFloat(h.floatValue)
        } else {
            println("计算行高 \(__FUNCTION__) \(indexPath)")
            let cell = tableView.dequeueReusableCellWithIdentifier(info.cellId) as! StatusCell
            let height = cell.cellHeight(info.status)
            
            // 将行高添加到缓存 - swift 中向 NSCache/NSArray/NSDictrionary 中添加数值不需要包装
            rowHeightCache!.setObject(height, forKey: "\(info.status.id)")
            
            return cell.cellHeight(info.status)
        }
    }
    
    // 预估行高，可以提高性能
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 300
    }
}
