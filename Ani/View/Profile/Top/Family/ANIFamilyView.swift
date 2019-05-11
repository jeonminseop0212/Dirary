//
//  ANIFamillyView.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/17.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseUI

protocol ANIFamilyViewDelegate {
  func presentImageBrowser(index: Int, imageUrls: [String])
}

class ANIFamilyView: UIView {
  
  private weak var familyCollectionView: UICollectionView?
  
  var user: FirebaseUser? {
    didSet {
      guard let familyCollectionView = self.familyCollectionView else { return }
      familyCollectionView.reloadData()
    }
  }
  
  var delegate: ANIFamilyViewDelegate?
  
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
    flowLayout.minimumInteritemSpacing = 0
    flowLayout.minimumLineSpacing = 0
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    let id = NSStringFromClass(ANIFamilyViewCell.self)
    collectionView.register(ANIFamilyViewCell.self, forCellWithReuseIdentifier: id)
    collectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    collectionView.backgroundColor = .white
    collectionView.alwaysBounceHorizontal = true
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.delegate = self
    collectionView.dataSource = self
    addSubview(collectionView)
    collectionView.edgesToSuperview()
    self.familyCollectionView = collectionView
  }
}

//MARK: UICollectionViewDataSource
extension ANIFamilyView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if let user = self.user, let familyImageUrls = user.familyImageUrls {
      return 1 + familyImageUrls.count
    } else {
      return 1
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let id = NSStringFromClass(ANIFamilyViewCell.self)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ANIFamilyViewCell
    
    if indexPath.item == 0 {
      if let user = self.user, let profileImageUrl = user.profileImageUrl {
        cell.familySmallImageViewBG?.alpha = 0.0
        cell.familyBigImageView?.alpha = 1.0
        cell.familyBigImageView?.sd_setImage(with: URL(string: profileImageUrl), completed: nil)
      }
    } else {
      if let user = self.user, let familyImageUrls = user.familyImageUrls {
        cell.familyBigImageView?.alpha = 0.0
        cell.familySmallImageViewBG?.alpha = 1.0
        cell.familySmallImageView?.sd_setImage(with: URL(string: familyImageUrls[indexPath.item - 1]), completed: nil)
      }
    }
    
    return cell
  }
}

//MARK: UICollectionViewDelegateFlowLayout
extension ANIFamilyView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let size = CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
    return size
  }
}

//MARK: UICollectionViewDelegate
extension ANIFamilyView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let user = self.user,
          let profileImageUrl = user.profileImageUrl else { return }
    
    var imageUrls = [String]()
    imageUrls.append(profileImageUrl)
    if let familyImageUrls = user.familyImageUrls {
      for familyImageUrl in familyImageUrls {
        imageUrls.append(familyImageUrl)
      }
    }
    
    self.delegate?.presentImageBrowser(index: indexPath.item, imageUrls: imageUrls)
  }
}
