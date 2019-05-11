//
//  ANIQnaImagesCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/18.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANIQnaImagesCell: UICollectionViewCell {
  
  var imageView: UIImageView?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //imageView
    let imageView = UIImageView()
    imageView.backgroundColor = ANIColor.gray
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 10.0
    imageView.layer.masksToBounds = true
    addSubview(imageView)
    imageView.edgesToSuperview()
    self.imageView = imageView
  }
}
