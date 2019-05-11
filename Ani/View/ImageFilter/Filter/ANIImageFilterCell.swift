//
//  ANIImageFilterCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/12.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANIImageFilterCell: UICollectionViewCell {
  
  weak var filterNameLabel: UILabel?
  static let FILTER_IMAGE_VIEW_TOP_MARGIN: CGFloat = 8.0
  static let FILTER_IMAGE_VIEW_WIDTH: CGFloat = 100.0
  weak var filterImageView: UIImageView?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var isHighlighted: Bool {
    didSet {
      filterNameLabel?.textColor = isHighlighted ? ANIColor.dark : ANIColor.gray
    }
  }
  
  override var isSelected: Bool {
    didSet {
      filterNameLabel?.textColor = isSelected ? ANIColor.dark : ANIColor.gray
    }
  }
  
  private func setup() {    
    //filterImageView
    let filterImageView = UIImageView()
    filterImageView.backgroundColor = ANIColor.gray
    filterImageView.dropShadow(opacity: 0.2)
    addSubview(filterImageView)
    filterImageView.width(ANIImageFilterCell.FILTER_IMAGE_VIEW_WIDTH)
    filterImageView.height(ANIImageFilterCell.FILTER_IMAGE_VIEW_WIDTH)
    filterImageView.centerYToSuperview()
    filterImageView.centerXToSuperview()
    self.filterImageView = filterImageView
    
    //filterNameLabel
    let filterNameLabel = UILabel()
    filterNameLabel.textAlignment = .center
    filterNameLabel.textColor = ANIColor.gray
    filterNameLabel.font = UIFont.boldSystemFont(ofSize: 12.0)
    addSubview(filterNameLabel)
    filterNameLabel.leftToSuperview()
    filterNameLabel.rightToSuperview()
    filterNameLabel.bottomToTop(of: filterImageView, offset: -10.0)
    self.filterNameLabel = filterNameLabel
  }
}
