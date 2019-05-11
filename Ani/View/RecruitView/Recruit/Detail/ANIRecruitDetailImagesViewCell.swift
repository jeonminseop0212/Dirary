//
//  ANIRecruitDetailImagesViewCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/04/28.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANIRecruitDetailImagesViewCell: UICollectionViewCell {
  
  weak var imageView: UIImageView?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    let imageView = UIImageView()
    imageView.backgroundColor = ANIColor.bg
    imageView.layer.cornerRadius = 10.0
    imageView.layer.masksToBounds = true
    imageView.contentMode = .scaleAspectFit
    addSubview(imageView)
    imageView.edgesToSuperview()
    self.imageView = imageView
  }
}
