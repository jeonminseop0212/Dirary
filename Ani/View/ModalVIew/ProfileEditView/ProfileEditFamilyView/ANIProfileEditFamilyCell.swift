//
//  ANIProfileEditFamilyCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/19.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIProfileEditFamilyCellDelegate {
  func imageDeleteImageViewBGTapped(index: Int)
}

class ANIProfileEditFamilyCell: UICollectionViewCell {
  
  private let FAMILY_IMAGE_VIEW_BG_HEIGHT: CGFloat = 80.0
  private weak var familyImageViewBG: UIView?
  weak var familyImageView: UIImageView?
  private let IMAGE_PICK_IMAGE_VIEW_HEGITH: CGFloat = 25.0
  weak var imagePickImageView: UIImageView?
  private let IMAGE_DELETE_IMAGE_VIEW_BG_HEIGHT: CGFloat = 30.0
  weak var imageDeleteImageViewBG: UIView?
  private weak var imageDeleteImageView: UIImageView?
  
  var index: Int?
  var delegate: ANIProfileEditFamilyCellDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //imageViewBG
    let imageViewBG = UIView()
    addSubview(imageViewBG)
    imageViewBG.width(FAMILY_IMAGE_VIEW_BG_HEIGHT)
    imageViewBG.height(FAMILY_IMAGE_VIEW_BG_HEIGHT)
    imageViewBG.centerInSuperview()
    self.familyImageViewBG = imageViewBG
    
    //imageView
    let imageView = UIImageView()
    imageView.backgroundColor = ANIColor.gray
    imageView.contentMode = .scaleAspectFit
    imageViewBG.addSubview(imageView)
    imageView.layer.cornerRadius = FAMILY_IMAGE_VIEW_BG_HEIGHT / 2
    imageView.layer.masksToBounds = true
    imageView.edgesToSuperview()
    self.familyImageView = imageView
    
    //imagePickImageView
    let imagePickImageView = UIImageView()
    imagePickImageView.contentMode = .scaleAspectFit
    imagePickImageView.image = UIImage(named: "imagePickButton")
    imagePickImageView.layer.cornerRadius = IMAGE_PICK_IMAGE_VIEW_HEGITH / 2
    imagePickImageView.layer.masksToBounds = true
    imageViewBG.addSubview(imagePickImageView)
    imagePickImageView.width(IMAGE_PICK_IMAGE_VIEW_HEGITH)
    imagePickImageView.height(IMAGE_PICK_IMAGE_VIEW_HEGITH)
    imagePickImageView.rightToSuperview()
    imagePickImageView.bottomToSuperview()
    self.imagePickImageView = imagePickImageView

    //imageDeleteImageViewBG
    let imageDeleteImageViewBG = UIView()
    let deleteTapGesture = UITapGestureRecognizer(target: self, action: #selector(imageDeleteBGTapped))
    imageDeleteImageViewBG.addGestureRecognizer(deleteTapGesture)
    imageViewBG.addSubview(imageDeleteImageViewBG)
    imageDeleteImageViewBG.topToSuperview()
    imageDeleteImageViewBG.rightToSuperview()
    imageDeleteImageViewBG.width(IMAGE_DELETE_IMAGE_VIEW_BG_HEIGHT)
    imageDeleteImageViewBG.height(IMAGE_DELETE_IMAGE_VIEW_BG_HEIGHT)
    self.imageDeleteImageViewBG = imageDeleteImageViewBG
    
    //imageDeleteImageView
    let imageDeleteImageView = UIImageView()
    imageDeleteImageView.image = UIImage(named: "imageDeleteButton")
    imageDeleteImageViewBG.addSubview(imageDeleteImageView)
    imageDeleteImageView.topToSuperview()
    imageDeleteImageView.rightToSuperview()
    imageDeleteImageView.width(IMAGE_PICK_IMAGE_VIEW_HEGITH)
    imageDeleteImageView.height(IMAGE_PICK_IMAGE_VIEW_HEGITH)
    self.imageDeleteImageView = imageDeleteImageView
  }
  
  @objc private func imageDeleteBGTapped() {
    guard let index = self.index else { return }
    
    self.delegate?.imageDeleteImageViewBGTapped(index: index)
  }
}
