//
//  StatusCell.swift
//  HMWeibo04
//
//  Created by apple on 15/3/6.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit

class StatusCell: UITableViewCell {

    /// 头像
    @IBOutlet weak var iconImage: UIImageView!
    /// 姓名
    @IBOutlet weak var nameLabel: UILabel!
    /// 会员图标
    @IBOutlet weak var memberIcon: UIImageView!
    /// 认证图标
    @IBOutlet weak var vipIcon: UIImageView!
    /// 时间
    @IBOutlet weak var timeLabel: UILabel!
    /// 来源
    @IBOutlet weak var sourceLabel: UILabel!
    /// 微博正文
    @IBOutlet weak var contentLabel: UILabel!
    
    /// 配图视图
    @IBOutlet weak var pictureView: UICollectionView!
    /// 配图视图宽度
    @IBOutlet weak var pictureViewWidth: NSLayoutConstraint!
    /// 配图视图高度
    @IBOutlet weak var pictureViewHeight: NSLayoutConstraint!
    /// 配图视图布局
    @IBOutlet weak var pictureViewLayout: UICollectionViewFlowLayout!
    
    /// 底部工具视图
    @IBOutlet weak var bottomToolView: UIView!
    /// 转发微博文本
    @IBOutlet weak var forwardLabel: UILabel!
    
    /// 微博数据 － 设置 cell 内容
    var status: Status? {
        didSet {
            nameLabel.text = status!.user!.name
            timeLabel.text = status!.created_at
            sourceLabel.text = status!.source
            contentLabel.text = status!.text
            
            // 头像
            if let iconUrl = status?.user?.profile_image_url {
                NetworkManager.sharedManager.requestImage(iconUrl) { (result, error) -> () in
                    if let image = result as? UIImage {
                        self.iconImage.image = image
                    }
                }
            }
            // 认证图标
            vipIcon.image = status?.user?.verifiedImage
            // 会员图标
            memberIcon.image = status?.user?.mbImage
            
            let pSize = calcPictureViewSize()
            pictureViewWidth.constant = pSize.viewSize.width
            pictureViewHeight.constant = pSize.viewSize.height
            pictureViewLayout.itemSize = pSize.itemSize
            
            // 重新刷新配图视图 － 强制数据源方法重新执行
            pictureView.reloadData()
            
            // 设置转发微博文字
            if status?.retweeted_status != nil {
                forwardLabel.text = status!.retweeted_status!.user!.name! + ":" + status!.retweeted_status!.text!
            }
        }
    }
    
    ///  返回可重用标识符
    class func cellIdentifier(status: Status) -> String {
        if status.retweeted_status != nil {
            // 转发微博
            return "ForwardCell"
        } else {
            // 原创微博
            return "HomeCell"
        }
    }
    
    ///  返回微博数据对应的行高
    func cellHeight(status: Status) -> CGFloat {
        
        // 设置微博数据
        self.status = status
        
        // 强制更新布局 - 如果执行非常频繁，性能并不好！
        // 计算行高的方法应该尽量简单！
        layoutIfNeeded()
        
        // 返回工具视图底部的高度
        return CGRectGetMaxY(bottomToolView.frame)
    }
    
    ///  真正开始创建表格Cell的时候，才会被调用，从 storyboard 加载 bounds/frame 都还没有设置
    override func awakeFromNib() {
        super.awakeFromNib()

        // 设置微博正文换行的宽度
        contentLabel.preferredMaxLayoutWidth = UIScreen.mainScreen().bounds.width - 30
        // 如果是原创微博 cell 中不包含 forwardLabel
        forwardLabel?.preferredMaxLayoutWidth = UIScreen.mainScreen().bounds.width - 30
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // 定义照片被选择的闭包（参数：选中的微博数据&照片索引）
    var photoDidSelected: ((status: Status, photoIndex: Int)->())?
}

///  配图视图数据源方法
extension StatusCell: UICollectionViewDataSource, UICollectionViewDelegate {

    /// cell 被选中方法
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
     
        // 把点击事件传递给 tableViewCell
        // 判断 `tablViewCell` 是否有闭包
        // ** 如果视图与用户发生交互，应该想办法将消息传递给视图控制器
        if self.photoDidSelected != nil {
            // 执行闭包
            self.photoDidSelected!(status: status!, photoIndex: indexPath.item)
        }
    }
    
    ///  配图数量
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 配图的数量
        return status?.pictureUrls?.count ?? 0
    }

    ///  配图Cell
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PictureCell", forIndexPath: indexPath) as! PictureCell
        
        // 设置配图的图像路径
        cell.urlString = status!.pictureUrls![indexPath.item].thumbnail_pic
        
        return cell
    }
    
    ///  计算配图视图大小
    /**
    1. 如果没有图像，大小是 0,0
    2. 如果有一张图像，视图大小：是图像大小，itemSize：同样也应该是 图像大小
    3. 多张图像，最多九张
    4. 如果4张，视图大小：视图大小 2 * 2，itemSize：90 * 90
    5. 其他：视图大小，要计算行数 1-3 一行，4-6 两行，三行，宽度固定
    */
    func calcPictureViewSize() -> (itemSize: CGSize, viewSize: CGSize) {
        let s: CGFloat = 90
        var itemSize = CGSizeMake(s, s)
        // 配图视图大小
        var viewSize = CGSizeZero
        
        // 配图图片的个数
        let count = status?.pictureUrls?.count ?? 0
        
        println("配图数量 \(count)")
        // 1. 如果没有图像
        if count == 0 {
            return (itemSize, viewSize)
        }
        
        // 2. 如果有一张图像，需要和图像大小一致
        if count == 1 {
            // 拿到被缓存的图像
            let path = NetworkManager.sharedManager.fullImageCachePath(status!.pictureUrls![0].thumbnail_pic!)
            // 实例化图像 － 图像有可能下载失败
            if let image = UIImage(contentsOfFile: path) {
                return (image.size, image.size)
            } else {
                return (itemSize, viewSize)
            }
        }
        
        // 3. 4张图片
        // 间距
        let m: CGFloat = 10
        if count == 4 {
            viewSize = CGSizeMake(s * 2 + m, s * 2 + m)
        } else {
            /**
            1,2,3 = 1
            5,6 = 2
            7,8,9 = 3
            */
            let row = (count - 1) / 3
            viewSize = CGSizeMake(3 * s + 2 * m, (CGFloat(row) + 1) * s + CGFloat(row) * m)
        }
        
        return (itemSize, viewSize)
    }
}

///  配图cell
class PictureCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    /// 图像的 url 字符串
    var urlString: String? {
        didSet {
            // 1. 图像缓存路径
            let path = NetworkManager.sharedManager.fullImageCachePath(urlString!)
            // 2. 实例化图像
            let image = UIImage(contentsOfFile: path)
            
            imageView.image = image
        }
    }
}

