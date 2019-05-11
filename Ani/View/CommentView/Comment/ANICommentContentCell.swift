//
//  ANIContentCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/21.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//
import UIKit

class ANICommentContentCell: UITableViewCell {
  
  private weak var storyLabel: UILabel?
  
  private let BOTTOM_MARGIN_AREA_HEIGHT: CGFloat = 35.0
  private weak var bottomMarginArea: UIView?
  private weak var bottomLabel: UILabel?
  
  var content: String? {
    didSet {
      guard let storyLabel = self.storyLabel else { return }
      storyLabel.text = content
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
    
    //storyLabel
    let storyLabel = UILabel()
    storyLabel.textColor = ANIColor.dark
    storyLabel.font = UIFont.systemFont(ofSize: 15.0)
    storyLabel.numberOfLines = 0
    addSubview(storyLabel)
    let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    storyLabel.edgesToSuperview(excluding: .bottom, insets: insets)
    self.storyLabel = storyLabel
    
    //bottomMarginArea
    let bottomMarginArea = UIView()
    bottomMarginArea.backgroundColor = ANIColor.lightGray
    addSubview(bottomMarginArea)
    bottomMarginArea.topToBottom(of: storyLabel, offset: 20.0)
    bottomMarginArea.edgesToSuperview(excluding: .top)
    bottomMarginArea.height(BOTTOM_MARGIN_AREA_HEIGHT)
    self.bottomMarginArea = bottomMarginArea
    
    //bottomLabel
    let bottomLabel = UILabel()
    bottomLabel.textColor = ANIColor.subTitle
    bottomLabel.text = "コメント"
    bottomLabel.font = UIFont.boldSystemFont(ofSize: 15.0)
    bottomMarginArea.addSubview(bottomLabel)
    bottomLabel.leftToSuperview(offset: 10.0)
    bottomLabel.centerYToSuperview()
    self.bottomLabel = bottomLabel
  }
}
