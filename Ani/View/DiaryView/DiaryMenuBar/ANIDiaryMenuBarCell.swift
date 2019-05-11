//
//  ANICommunityMenuBarCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/08.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANIDiaryMenuBarCell: UICollectionViewCell {
  var menuImageView: UIImageView?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    let menuImageView = UIImageView()
    menuImageView.contentMode = .center
    addSubview(menuImageView)
    menuImageView.centerInSuperview()
    menuImageView.width(21.0)
    menuImageView.height(21.0)
    self.menuImageView = menuImageView
  }
}
