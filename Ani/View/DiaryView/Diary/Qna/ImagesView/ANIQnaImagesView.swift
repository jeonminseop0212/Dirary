//
//  ANIQnaImageView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/18.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import SDWebImage

class ANIQnaImagesView: UIView {
  
  private weak var imagesCollectionView: UICollectionView?
  
  var imageUrls = [String]() {
    didSet {
      for subview in self.subviews{
        subview.removeFromSuperview()
      }
      setup()
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)    
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //imagesCollectionView
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.minimumLineSpacing = 5.0
    flowLayout.scrollDirection = .horizontal
    let imagesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    imagesCollectionView.backgroundColor = .white
    let id = NSStringFromClass(ANIQnaImagesCell.self)
    imagesCollectionView.register(ANIQnaImagesCell.self, forCellWithReuseIdentifier: id)
    imagesCollectionView.contentInset = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 10.0)
    imagesCollectionView.dataSource = self
    imagesCollectionView.delegate = self
    imagesCollectionView.showsHorizontalScrollIndicator = false
    imagesCollectionView.alwaysBounceHorizontal = true
    addSubview(imagesCollectionView)
    imagesCollectionView.edgesToSuperview()
    self.imagesCollectionView = imagesCollectionView
  }
}

//MARK: UICollectionViewDataSource
extension ANIQnaImagesView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return imageUrls.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let id = NSStringFromClass(ANIQnaImagesCell.self)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ANIQnaImagesCell
    cell.imageView?.sd_setImage(with: URL(string: imageUrls[indexPath.item]), completed: nil)
    return cell
  }
}

//MARK: UICollectionViewDelegate
extension ANIQnaImagesView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    ANINotificationManager.postImageCellTapped(tapCellItem: (indexPath.item, imageUrls))
  }
}

//MARK: UICollectionViewDelegateFlowLayout
extension ANIQnaImagesView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
  }
}
