//
//  ANIStoryImagesView.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/08.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

class ANIStoryImagesView: UIView {
  
  private weak var imagesCollectionView: UICollectionView?
  private let PAGE_CONTROL_HEIGHT: CGFloat = 30.0
  private var pageControlHeightConstraint: Constraint?
  weak var pageControl: UIPageControl?
  
  var imageUrls = [String]() {
    didSet {
      for subview in self.subviews{
        subview.removeFromSuperview()
      }
      setup()
      setupPageControlHeight(imageUrls: imageUrls)
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //iamgesCollectionView
    let flowLayot = UICollectionViewFlowLayout()
    flowLayot.scrollDirection = .horizontal
    flowLayot.minimumLineSpacing = 0
    flowLayot.minimumInteritemSpacing = 0
    let imagesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayot)
    imagesCollectionView.delegate = self
    imagesCollectionView.dataSource = self
    imagesCollectionView.isPagingEnabled = true
    imagesCollectionView.showsHorizontalScrollIndicator = false
    imagesCollectionView.backgroundColor = ANIColor.gray
    let id = NSStringFromClass(ANIStoryImagesCell.self)
    imagesCollectionView.register(ANIStoryImagesCell.self, forCellWithReuseIdentifier: id)
    addSubview(imagesCollectionView)
    imagesCollectionView.height(UIScreen.main.bounds.width, priority: .defaultHigh)
    imagesCollectionView.edgesToSuperview(excluding: .bottom)
    self.imagesCollectionView = imagesCollectionView
    
    //pageControl
    let pageControl = UIPageControl()
    pageControl.pageIndicatorTintColor = ANIColor.gray
    pageControl.currentPageIndicatorTintColor = ANIColor.emerald
    pageControl.currentPage = 0
    pageControl.isUserInteractionEnabled = false
    addSubview(pageControl)
    pageControl.topToBottom(of: imagesCollectionView, offset: 5.0)
    pageControl.leftToSuperview()
    pageControl.rightToSuperview()
    pageControlHeightConstraint = pageControl.height(PAGE_CONTROL_HEIGHT, priority: .defaultHigh)
    pageControl.bottomToSuperview()
    self.pageControl = pageControl
  }
  
  private func setupPageControlHeight(imageUrls: [String]) {
    guard let pageControlHeightConstraint = self.pageControlHeightConstraint,
          let pageControl = self.pageControl else { return }
    
    if imageUrls.count < 2 {
      pageControlHeightConstraint.constant = 0
      pageControl.alpha = 0.0
    } else {
      pageControlHeightConstraint.constant = PAGE_CONTROL_HEIGHT
      pageControl.alpha = 1.0
    }
  }
}

//MARK: UICollectionViewDataSource
extension ANIStoryImagesView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return imageUrls.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let id = NSStringFromClass(ANIStoryImagesCell.self)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ANIStoryImagesCell
    cell.imageView?.sd_setImage(with: URL(string: imageUrls[indexPath.item]), completed: nil)
    return cell
  }
}

//MARK: UICollectionViewDelegate
extension ANIStoryImagesView: UICollectionViewDelegate {
  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    guard let pageControl = self.pageControl else { return }
    pageControl.currentPage = Int(targetContentOffset.pointee.x / pageControl.frame.width)
  }
}

//MARK: UICollectionViewDelegateFlowLayout
extension ANIStoryImagesView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let size = CGSize(width: collectionView.frame.width, height: collectionView.frame.width)
    return size
  }
}
