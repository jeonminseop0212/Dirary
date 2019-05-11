//
//  ANIRecruitContributeImagesView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/16.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIRecruitContributionImagesViewDelegate {
  func imagesPickCellTapped()
  func imageDelete(index: Int)
}

class ANIRecruitContributionImagesView: UIView {
  
  private weak var imagesViewCollectionView: UICollectionView?
  
  var introduceImages = [UIImage?]() {
    didSet {
      reloadLayout()
    }
  }
  
  var delegate: ANIRecruitContributionImagesViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.scrollDirection = .horizontal
    let imagesViewCollectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    imagesViewCollectionView.alwaysBounceHorizontal = true
    imagesViewCollectionView.showsHorizontalScrollIndicator = false
    imagesViewCollectionView.delegate = self
    imagesViewCollectionView.dataSource = self
    imagesViewCollectionView.backgroundColor = .white
    imagesViewCollectionView.contentInset = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 10.0)
    let id = NSStringFromClass(ANIRecruitContributionImagesCell.self)
    imagesViewCollectionView.register(ANIRecruitContributionImagesCell.self, forCellWithReuseIdentifier: id)
    addSubview(imagesViewCollectionView)
    imagesViewCollectionView.edgesToSuperview()
    self.imagesViewCollectionView = imagesViewCollectionView
  }
  
  private func reloadLayout() {
    guard let imagesViewCollectionView = self.imagesViewCollectionView else { return }
    imagesViewCollectionView.reloadData()
  }
}

//MARK: UICollectionViewDataSource
extension ANIRecruitContributionImagesView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return introduceImages.count + 1
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let id = NSStringFromClass(ANIRecruitContributionImagesCell.self)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ANIRecruitContributionImagesCell
    
    if indexPath.item < introduceImages.count {
      cell.imageView?.contentMode = .scaleAspectFill
      cell.imageView?.image = introduceImages[indexPath.item]
      cell.deleteButton?.alpha = 1.0
      cell.deleteButton?.tag = indexPath.row
      cell.delegate = self
    } else {
      cell.imageView?.backgroundColor = ANIColor.bg
      cell.imageView?.contentMode = .center
      cell.imageView?.image = UIImage(named: "imagesPickButton")
      cell.deleteButton?.alpha = 0.0
    }
    
    return cell
  }
}

//MARK: UICollectionViewDelegate
extension ANIRecruitContributionImagesView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if indexPath.item == introduceImages.count {
      self.delegate?.imagesPickCellTapped()
    }
  }
}

//MARK: UICollectionViewDelegateFlowLayout
extension ANIRecruitContributionImagesView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    if introduceImages.isEmpty {
      let sideInset: CGFloat = 20.0
      collectionView.isScrollEnabled = false
      return CGSize(width: collectionView.frame.width - sideInset, height: collectionView.frame.height)
    } else {
      collectionView.isScrollEnabled = true
      return CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
    }
  }
}

//MARK: ANIRecruitContributionImagesCellDelegate
extension ANIRecruitContributionImagesView: ANIRecruitContributionImagesCellDelegate {
  func deleteButtonTapped(index: Int) {
    self.delegate?.imageDelete(index: index)
  }
}
