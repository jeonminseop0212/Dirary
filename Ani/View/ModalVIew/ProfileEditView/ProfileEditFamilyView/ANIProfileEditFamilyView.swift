//
//  ANIProfileEditFamilyView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/19.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIProfileEditFamilyViewDelegate {
  func imagePickerCellTapped()
  func imageEditButtonTapped(index: Int)
  func familyImageDelete(index: Int)
}

class ANIProfileEditFamilyView: UIView {
  
  private weak var familyCollectionView: UICollectionView?
  
  var profileImage: UIImage? {
    didSet {
      guard let familyCollectionView = self.familyCollectionView else { return }
      
      familyCollectionView.reloadData()
    }
  }
  var familyImages: [UIImage?]? {
    didSet {
      guard let familyCollectionView = self.familyCollectionView else { return }
      
      familyCollectionView.reloadData()
    }
  }
  
  var currentUser: FirebaseUser? {
    didSet {
      guard let familyCollectionView = self.familyCollectionView else { return }
      
      familyCollectionView.reloadData()
    }
  }
  
  var delegate: ANIProfileEditFamilyViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //familyCollectionView
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.scrollDirection = .horizontal
    flowLayout.minimumInteritemSpacing = 0
    flowLayout.minimumLineSpacing = 0
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    let id = NSStringFromClass(ANIProfileEditFamilyCell.self)
    collectionView.register(ANIProfileEditFamilyCell.self, forCellWithReuseIdentifier: id)
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
extension ANIProfileEditFamilyView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if let familyImages = self.familyImages {
      return 2 + familyImages.count
    } else if let currentUser = self.currentUser, let familyImageUrls = currentUser.familyImageUrls {
      return 2 + familyImageUrls.count
    } else {
      return 2
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let id = NSStringFromClass(ANIProfileEditFamilyCell.self)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ANIProfileEditFamilyCell
    
    cell.index = indexPath.row
    cell.delegate = self
    
    if indexPath.item == 0 {
      cell.imagePickImageView?.alpha = 1.0
      cell.imageDeleteImageViewBG?.alpha = 0.0
      if let profileImage = self.profileImage {
        cell.familyImageView?.image = profileImage
      } else if let currentUser = currentUser, let profileImageUrl = currentUser.profileImageUrl {
        cell.familyImageView?.sd_setImage(with: URL(string: profileImageUrl), completed: nil)
      }
    } else {
      if let familyImages = self.familyImages {
        if indexPath.item != familyImages.count + 1 {
          cell.imagePickImageView?.alpha = 1.0
          cell.imageDeleteImageViewBG?.alpha = 1.0
          cell.familyImageView?.image = familyImages[indexPath.item - 1]
        } else {
          cell.imagePickImageView?.alpha = 0.0
          cell.imageDeleteImageViewBG?.alpha = 0.0
          cell.familyImageView?.image = UIImage(named: "familyImageAdd")
        }
      } else if let currentUser = self.currentUser, let familyImageUrls = currentUser.familyImageUrls {
        if indexPath.item == familyImageUrls.count + 1 {
          cell.imagePickImageView?.alpha = 0.0
          cell.imageDeleteImageViewBG?.alpha = 0.0
          cell.familyImageView?.image = UIImage(named: "familyImageAdd")
        } else {
          cell.imagePickImageView?.alpha = 1.0
          cell.imageDeleteImageViewBG?.alpha = 1.0
          cell.familyImageView?.sd_setImage(with: URL(string: familyImageUrls[indexPath.item - 1]), completed: nil)
        }
      } else {
        cell.imagePickImageView?.alpha = 0.0
        cell.imageDeleteImageViewBG?.alpha = 0.0
        cell.familyImageView?.image = UIImage(named: "familyImageAdd")
      }
    }
    
    return cell
  }
}

//MARK: UICollectionViewDelegate
extension ANIProfileEditFamilyView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if indexPath.item == 0 {
      self.delegate?.imageEditButtonTapped(index: indexPath.item)
    } else {
      if let familyImages = self.familyImages {
        if indexPath.item == familyImages.count + 1 {
          self.delegate?.imagePickerCellTapped()
        } else {
          self.delegate?.imageEditButtonTapped(index: indexPath.item)
        }
      } else if let currentUser = self.currentUser, let familyImageUrls = currentUser.familyImageUrls {
        if indexPath.item == familyImageUrls.count + 1 {
          self.delegate?.imagePickerCellTapped()
        } else {
          self.delegate?.imageEditButtonTapped(index: indexPath.item)
        }
      } else {
        self.delegate?.imagePickerCellTapped()
      }
    }
  }
}

//MARK: UICollectionViewDelegateFlowLayout
extension ANIProfileEditFamilyView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let size = CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
    return size
  }
}

//MARK: ANIProfileEditFamilyCellDelegate
extension ANIProfileEditFamilyView: ANIProfileEditFamilyCellDelegate {
  func imageDeleteImageViewBGTapped(index: Int) {
    self.delegate?.familyImageDelete(index: index)
  }
}
