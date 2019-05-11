//
//  ANIContributionImagesView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/17.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIContributionImagesViewDelegate {
  func imagesPickCellTapped()
  func imageDelete(index: Int)
  func videoDelete()
}

class ANIContributionImagesView: UIView {
  
  private weak var imagesViewCollectionView: UICollectionView?
  
  var contentImages = [UIImage?]() {
    didSet {
      reloadLayout()
    }
  }

  var videoLength: Int = 0
  var thumbnailImage: UIImage? {
    didSet {
      reloadLayout()
    }
  }
  
  var selectedContributionMode: ContributionMode?
  
  var delegate: ANIContributionImagesViewDelegate?
  
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
    let imagesCellId = NSStringFromClass(ANIContributionImagesCell.self)
    imagesViewCollectionView.register(ANIContributionImagesCell.self, forCellWithReuseIdentifier: imagesCellId)
    let videoCellId = NSStringFromClass(ANIContributionVideoCell.self)
    imagesViewCollectionView.register(ANIContributionVideoCell.self, forCellWithReuseIdentifier: videoCellId)
    addSubview(imagesViewCollectionView)
    imagesViewCollectionView.edgesToSuperview()
    self.imagesViewCollectionView = imagesViewCollectionView
  }
  
  private func reloadLayout() {
    guard let imagesViewCollectionView = self.imagesViewCollectionView else { return }
    imagesViewCollectionView.reloadData()
  }
}

extension ANIContributionImagesView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if thumbnailImage != nil {
      return 2
    } else {
      return contentImages.count + 1
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let thumbnailImage = self.thumbnailImage {
      let videoCellId = NSStringFromClass(ANIContributionVideoCell.self)
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: videoCellId, for: indexPath) as! ANIContributionVideoCell
      
      if indexPath.item == 0 {
        cell.coverImageView?.contentMode = .scaleAspectFill
        cell.coverImageView?.image = thumbnailImage
        cell.bottomAreaBackGroundView?.alpha = 1.0
        var videoLengthString = "\(videoLength)"
        if videoLength < 10 {
          videoLengthString = "0" + videoLengthString
        }
        cell.videoLengthLabel?.text = "00:" + videoLengthString
        cell.deleteButton?.alpha = 1.0
        cell.delegate = self
      } else {
        cell.coverImageView?.backgroundColor = ANIColor.bg
        cell.coverImageView?.contentMode = .center
        cell.coverImageView?.image = UIImage(named: "imagesPickButton")
        cell.bottomAreaBackGroundView?.alpha = 0.0
        cell.deleteButton?.alpha = 0.0
      }
      
      return cell
    } else {
      let imagesCellId = NSStringFromClass(ANIContributionImagesCell.self)
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imagesCellId, for: indexPath) as! ANIContributionImagesCell
      
      if indexPath.item < contentImages.count {
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.image = contentImages[indexPath.item]
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
}

//MARK: UICollectionViewDelegate
extension ANIContributionImagesView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if thumbnailImage != nil {
      if indexPath.item == 1 {
        self.delegate?.imagesPickCellTapped()
      }
    } else if indexPath.item == contentImages.count {
      self.delegate?.imagesPickCellTapped()
    }
  }
}

//MARK: UICollectionViewDelegateFlowLayout
extension ANIContributionImagesView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    if thumbnailImage != nil {
      collectionView.isScrollEnabled = true
      return CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
    } else {
      if contentImages.isEmpty {
        let sideInset: CGFloat = 20.0
        collectionView.isScrollEnabled = false
        return CGSize(width: collectionView.frame.width - sideInset, height: collectionView.frame.height)
      } else {
        collectionView.isScrollEnabled = true
        return CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
      }
    }
  }
}

//MARK: ANIContributionImagesCellDelegate
extension ANIContributionImagesView: ANIContributionImagesCellDelegate {
  func deleteButtonTapped(index: Int) {
    self.delegate?.imageDelete(index: index)
  }
}

//MARK: ANIContributionVideoCellDelegate
extension ANIContributionImagesView: ANIContributionVideoCellDelegate {
  func deleteButtonTapped() {
    self.delegate?.videoDelete()
  }
}
