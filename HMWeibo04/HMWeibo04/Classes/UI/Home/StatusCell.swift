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
    
    /// 微博数据
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
        }
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
        let count = status?.pic_urls?.count ?? 0
        
        println("配图数量 \(count)")
        // 1. 如果没有图像
        if count == 0 {
            return (itemSize, viewSize)
        }
        
        // 2. 如果有一张图像，需要和图像大小一致
        if count == 1 {
            // 拿到被缓存的图像
            let path = NetworkManager.sharedManager.fullImageCachePath(status!.pic_urls![0].thumbnail_pic!)
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
    
    ///  真正开始创建表格Cell的时候，才会被调用，从 storyboard 加载 bounds/frame 都还没有设置
    override func awakeFromNib() {
        super.awakeFromNib()

        // 设置微博正文换行的宽度
        contentLabel.preferredMaxLayoutWidth = UIScreen.mainScreen().bounds.width - 30
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

///  配图视图数据源方法
extension StatusCell: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 配图的数量
        return status?.pic_urls?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PictureCell", forIndexPath: indexPath) as! PictureCell
        
        // 设置配图的图像路径
        cell.urlString = status!.pic_urls![indexPath.item].thumbnail_pic
        
        return cell
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

