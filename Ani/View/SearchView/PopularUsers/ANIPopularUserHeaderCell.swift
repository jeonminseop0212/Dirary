//
//  ANIPopularUserHeaderCell.swift
//  Ani
//
//  Created by jeonminseop on 2019/02/16.
//  Copyright © 2019 JeonMinseop. All rights reserved.
//

import UIKit

class ANIPopularUserHeaderCell: UICollectionViewCell {
  
  private weak var headerLabel: UILabel?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = ANIColor.bg
    
    //headerLabel
    let headerLabel = UILabel()
    headerLabel.text = "人気ユーザー"
    headerLabel.textColor = ANIColor.dark
    headerLabel.font = UIFont.boldSystemFont(ofSize: 15)
    addSubview(headerLabel)
    headerLabel.leftToSuperview()
    headerLabel.centerYToSuperview()
    self.headerLabel = headerLabel
  }
}
