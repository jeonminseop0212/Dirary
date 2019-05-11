//
//  ANINotiMessageCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/14.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANINotiMessageCell: UICollectionViewCell {
  
  private weak var messageView: ANIMessageView?
  
  var isCellSelected: Bool = false {
    didSet {
      guard let messageView = self.messageView else { return }
      
      messageView.isCellSelected = isCellSelected
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
    let messageView = ANIMessageView()
    addSubview(messageView)
    messageView.edgesToSuperview()
    self.messageView = messageView
  }
}
