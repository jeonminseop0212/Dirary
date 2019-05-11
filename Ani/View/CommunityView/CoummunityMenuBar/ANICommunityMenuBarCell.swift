//
//  ANICommunityMenuBarCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/08.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANICommunityMenuBarCell: UICollectionViewCell {
  var menuLabel: UILabel?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    let menuLabel = UILabel()
    menuLabel.textAlignment = .center
    menuLabel.font = UIFont.boldSystemFont(ofSize: 17)
    menuLabel.textColor = ANIColor.gray
    addSubview(menuLabel)
    menuLabel.edgesToSuperview()
    self.menuLabel = menuLabel
  }
  
  override var isHighlighted: Bool {
    didSet {
      menuLabel?.textColor = isHighlighted ? ANIColor.dark : ANIColor.gray
    }
  }
  
  override var isSelected: Bool {
    didSet {
      menuLabel?.textColor = isSelected ? ANIColor.dark : ANIColor.gray
    }
  }
}
