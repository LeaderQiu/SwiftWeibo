//
//  EmoticonsViewController.swift
//  HMWeibo04
//
//  Created by apple on 15/3/11.
//  Copyright (c) 2015年 heima. All rights reserved.
//

import UIKit

let reuseIdentifier = "Cell"

class EmoticonsViewController: UIViewController {

    @IBOutlet weak var layout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // 2. 定义代理 － weak，千万不要忘记 weak
    weak var delegate: EmoticonsViewControllerDelegate?
    
    /// 表情符号分组数组，每一个分组包含21个表情
    lazy var emoticonSection: [EmoticonsSection]? = {
        return EmoticonsSection.loadEmoticons()
    }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        println(self.collectionView)
        // 设置界面布局
        setupLayout()
    }
    
    /// 设置界面布局
    func setupLayout() {
        // 目标 3 ＊ 7 个按钮
        let row: CGFloat = 3
        let col: CGFloat = 7
        // item 之间的间距
        let m: CGFloat = 10
        
        // 计算 item 的大小
        let screenSize = self.collectionView.bounds.size
        let w = (screenSize.width - (col + 1) * m) / col
        
        layout.itemSize = CGSizeMake(w, w)
        layout.minimumInteritemSpacing = m
        layout.minimumLineSpacing = m
        
        // 每一个分组之间的边距
        layout.sectionInset = UIEdgeInsetsMake(m, m, m, m)
        
        // 滚动方向
        layout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        // 分页
        collectionView.pagingEnabled = true
    }
}

// 1. 定义协议
/**
    在 swift 中，除了类，还有"结构体"以及"枚举"都可以遵守协议！
    weak 关键字，是用在 ARC 中管理对象内存属性，weak 关键字只能描述一个对象

    也可以使用 @objc，要保证所有的参数，都是 OC 的
*/
protocol EmoticonsViewControllerDelegate: NSObjectProtocol {
    /// 选中了某一个标枪
    func emoticonsViewControllerDidSelectEmoticon(vc: EmoticonsViewController, emoticon: Emoticon)
}

/**
    接下来准备数据的时候，需要考虑每一个分组都刚好有21个cell
*/
extension EmoticonsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    /// 根据 indexPath 返回表情数据
    func emoticon(indexPath: NSIndexPath) -> Emoticon {
        return emoticonSection![indexPath.section].emoticons[indexPath.item]
    }
    
    /// cell 被选中
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // 通过代理传递撰写微博视图控制器做后续处理
        println(emoticon(indexPath))
        // 3. 通知代理执行方法，注意这里的 ?
        // 使用 ? 不需要判断代理是否实现方法
        delegate?.emoticonsViewControllerDidSelectEmoticon(self, emoticon: emoticon(indexPath))
    }
    
    /// 返回分组数量
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return emoticonSection?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emoticonSection![section].emoticons.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("EmoticonsCell", forIndexPath: indexPath) as! EmoticonCell
        
        cell.emoticon = emoticon(indexPath)
        
        return cell
    }
}

/// 表情的 cell
class EmoticonCell: UICollectionViewCell {
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var emojiLabel: UILabel!
    
    var emoticon: Emoticon? {
        didSet {
            // 设置图像
            if let path = emoticon?.imagePath {
                iconView.image = UIImage(contentsOfFile: path)
            } else {
                iconView.image = nil
            }
            // 设置 emoji
            emojiLabel.text = emoticon?.emoji
            
            // 是否是删除按钮
            if emoticon!.isDeleteButton {
                iconView.image = UIImage(named: "compose_emotion_delete_highlighted")
            }
        }
    }
}
