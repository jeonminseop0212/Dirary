//
//  CollectionViewCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/05.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

class ANIRecruitFilterCell: UICollectionViewCell {
  private weak var filterLabel: UILabel?
  private weak var selectButton: ANIImageButtonView?
  
  var filter: String = "" {
    didSet {
      guard let filterLabel = self.filterLabel else { return }
      
      filterLabel.text = filter
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = ANIColor.lightGray
    self.layer.cornerRadius = self.frame.height / 2
    self.layer.masksToBounds = true

    //filterLabel
    let filterLabel = UILabel()
    filterLabel.textAlignment = .center
    filterLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
    filterLabel.textColor = ANIColor.subTitle
    addSubview(filterLabel)
    filterLabel.leftToSuperview(offset: 15.0)
    filterLabel.centerYToSuperview()
    self.filterLabel = filterLabel
    
    //selectButton
    let selectButton = ANIImageButtonView()
    selectButton.image = UIImage(named: "basicInfoSelectButton")
    addSubview(selectButton)
    selectButton.width(10.0)
    selectButton.height(10.0)
    selectButton.leftToRight(of: filterLabel, offset: 5.0)
    selectButton.rightToSuperview(offset: -15.0)
    selectButton.centerY(to: filterLabel)
    self.selectButton = selectButton
  }
  
  static func sizeWithFilter(filter: String?) -> CGSize {
    guard let filter = filter else { return .zero }
    let tempLabel = UILabel()
    tempLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
    tempLabel.text = filter
    tempLabel.sizeToFit()
    return CGSize(width: tempLabel.frame.width + 30.0 + 12.0 + 5.0, height: tempLabel.frame.height + 14.0)
  }
}
