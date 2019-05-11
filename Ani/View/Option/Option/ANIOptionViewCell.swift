//
//  ANIOptionViewCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/22.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANIOptionViewCell: UITableViewCell {
  
  weak var titleLabel: UILabel?
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.selectionStyle = .none
    
    //titleLabel
    let titleLabel = UILabel()
    titleLabel.font = UIFont.systemFont(ofSize: 16.0)
    titleLabel.textColor = ANIColor.dark
    addSubview(titleLabel)
    let insets = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
    titleLabel.edgesToSuperview(insets: insets)
    self.titleLabel = titleLabel
  }
}
