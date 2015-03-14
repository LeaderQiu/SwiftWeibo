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
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("HomeCell", forIndexPath: indexPath) as! StatusCell
        
        let status = self.statusData!.statuses![indexPath.row]
        cell.status = status
        
        return cell
    }
}
