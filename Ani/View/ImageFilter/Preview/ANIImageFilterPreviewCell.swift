//
//  ANIImageFilterPreviewCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/11.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANIImageFilterPreviewCell: UICollectionViewCell {
  
  weak var imageView: UIImageView?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    backgroundColor = .white
    
    //imageView
    let imageView = UIImageView()
    imageView.backgroundColor = .white
    imageView.contentMode = .scaleAspectFit
    addSubview(imageView)
    imageView.edgesToSuperview()
    self.imageView = imageView
  }
}
