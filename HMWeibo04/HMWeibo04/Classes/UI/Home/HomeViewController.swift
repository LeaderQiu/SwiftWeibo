//
//  HomeViewController.swift
//  HMWeibo04
//
//  Created by apple on 15/3/5.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit

class HomeViewController: UITableViewController {

    /// 微博数据
    var statusData: StatusesData?
    /// 行高缓存
    lazy var rowHeightCache: NSCache? = {
        return NSCache()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
    }

    ///  加载微博数据
    func loadData() {
        SVProgressHUD.show()
        StatusesData.loadStatus { (data, error) -> () in
            if error != nil {
                println(error)
                SVProgressHUD.showInfoWithStatus("你的网络不给力")
                return
            }
            SVProgressHUD.dismiss()
            if data != nil {
                // 刷新表格数据
                self.statusData = data
                self.tableView.reloadData()
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
            cell.photoDidSelected = { (status: Status, photoIndex: Int)->() in
                println("\(status.text) \(photoIndex)")
                // 将数据传递给照片浏览器视图控制器
                // 使用类方法调用，不需要知道视图控制器太多的内部细节
                let vc = PhotoBrowserViewController.photoBrowserViewController()
                
                vc.urls = status.largeUrls
                vc.selectedIndex = photoIndex
                
                self.presentViewController(vc, animated: true, completion: nil)
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
