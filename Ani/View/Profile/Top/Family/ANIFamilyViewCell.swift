//
//  ANIFamilyViewCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/17.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANIFamilyViewCell: UICollectionViewCell {
  
  private let FAMILY_BIG_IMAGE_VIEW_HEIGHT: CGFloat = 80.0
  weak var familyBigImageView: UIImageView?
  private let FAMILY_SMALL_IMAGE_VIEW_HEIGHT: CGFloat = 69.0
  weak var familySmallImageViewBG: UIImageView?
  weak var familySmallImageView: UIImageView?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //familyBigImageView
    let familyBigImageView = UIImageView()
    familyBigImageView.contentMode = .scaleAspectFill
    familyBigImageView.backgroundColor = ANIColor.gray
    familyBigImageView.layer.cornerRadius = FAMILY_BIG_IMAGE_VIEW_HEIGHT / 2
    familyBigImageView.layer.masksToBounds = true
    addSubview(familyBigImageView)
    familyBigImageView.width(FAMILY_BIG_IMAGE_VIEW_HEIGHT)
    familyBigImageView.height(FAMILY_BIG_IMAGE_VIEW_HEIGHT)
    familyBigImageView.centerInSuperview()
    self.familyBigImageView = familyBigImageView
    
    //familySmallImageViewBG
    let familySmallImageViewBG = UIImageView()
    familySmallImageViewBG.image = UIImage(named: "familyBG")
    addSubview(familySmallImageViewBG)
    familySmallImageViewBG.edges(to: familyBigImageView)
    self.familySmallImageViewBG = familySmallImageViewBG
    
    //familySmallImageView
    let familySmallImageView = UIImageView()
    familySmallImageView.contentMode = .scaleAspectFill
    familySmallImageView.backgroundColor = ANIColor.gray
    familySmallImageView.layer.cornerRadius = FAMILY_SMALL_IMAGE_VIEW_HEIGHT / 2
    familySmallImageView.layer.masksToBounds = true
    familySmallImageViewBG.addSubview(familySmallImageView)
    familySmallImageView.width(FAMILY_SMALL_IMAGE_VIEW_HEIGHT)
    familySmallImageView.height(FAMILY_SMALL_IMAGE_VIEW_HEIGHT)
    familySmallImageView.centerInSuperview()
    self.familySmallImageView = familySmallImageView
  }
}
