//
//  ANIDeleteCommentCell.swift
//  Ani
//
//  Created by jeonminseop on 2019/01/11.
//  Copyright © 2019年 JeonMinseop. All rights reserved.
//

import UIKit

class ANIDeleteCommentCell: UITableViewCell {
  
  private weak var deleteLabel: UILabel?
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //deleteLabel
    let deleteLabel = UILabel()
    deleteLabel.textColor = ANIColor.dark
    deleteLabel.font = UIFont.systemFont(ofSize: 15.0)
    deleteLabel.text = "削除されたコメントです。"
    self.addSubview(deleteLabel)
    let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    deleteLabel.height(50.0)
    deleteLabel.edgesToSuperview(insets: insets)
    self.deleteLabel = deleteLabel
  }
}
