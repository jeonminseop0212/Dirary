//
//  CollectionViewCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/05.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

class ANISearchCategoryCell: UICollectionViewCell {
  
  private weak var base: UIView?
  var categoryLabel: UILabel?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    let base = UIView()
    base.layer.cornerRadius = self.frame.height / 2
    base.layer.masksToBounds = true
    base.layer.borderWidth = 1.5
    base.layer.borderColor = ANIColor.lightGray.cgColor
    addSubview(base)
    base.edgesToSuperview()
    self.base = base
    
    let categoryLabel = UILabel()
    categoryLabel.textAlignment = .center
    categoryLabel.font = UIFont.boldSystemFont(ofSize: 14)
    categoryLabel.textColor = ANIColor.subTitle
    base.addSubview(categoryLabel)
    let insets = UIEdgeInsets(top: 5.0, left: 15.0, bottom: 5.0, right: 15.0)
    categoryLabel.edgesToSuperview(insets: insets)
    self.categoryLabel = categoryLabel
  }
  
  static func sizeWithCategory(category: String?) -> CGSize {
    guard let category = category else { return .zero }
    let tempLabel = UILabel()
    tempLabel.text = category
    tempLabel.sizeToFit()
    return CGSize(width: tempLabel.frame.width + 30.0, height: tempLabel.frame.height + 10.0)
  }
  
  override var isHighlighted: Bool {
    didSet {
      guard let base = self.base else { return }
      
      base.backgroundColor = isHighlighted ? ANIColor.lightGray : .white
    }
  }
  
  override var isSelected: Bool {
    didSet {
      guard let base = self.base else { return }
      
      base.backgroundColor = isSelected ? ANIColor.lightGray : .white
    }
  }
}
