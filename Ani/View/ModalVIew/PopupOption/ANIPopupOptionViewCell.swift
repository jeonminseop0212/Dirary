//
//  ANIPopupOptionViewCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/09/04.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANIPopupOptionViewCell: UITableViewCell {

  private weak var optionLabel: UILabel?
  private weak var bottomLineImageView: UIImageView?
  
  var option: String = "" {
    didSet {
      guard let optionLabel = self.optionLabel else { return }
      
      optionLabel.text = option
    }
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //basic
    self.selectionStyle = .none
    
    //optionLabel
    let optionLabel = UILabel()
    optionLabel.textAlignment = .center
    optionLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
    optionLabel.textColor = ANIColor.dark
    addSubview(optionLabel)
    optionLabel.edgesToSuperview(excluding: .bottom)
    optionLabel.height(45, priority: .defaultHigh)
    self.optionLabel = optionLabel
    
    //bottomLine
    let bottomLineImageView = UIImageView()
    bottomLineImageView.image = UIImage(named: "line")
    addSubview(bottomLineImageView)
    bottomLineImageView.edgesToSuperview(excluding: .top)
    bottomLineImageView.topToBottom(of: optionLabel)
    bottomLineImageView.height(0.5, priority: .defaultHigh)
    self.bottomLineImageView = bottomLineImageView
  }
}
