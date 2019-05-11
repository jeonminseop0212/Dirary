//
//  ANICommunityViewCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/08.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANICommunityQnaCell: UICollectionViewCell {
  private weak var qnaView: ANIQnaView?
  
  var isCellSelected: Bool = false {
    didSet {
      guard let qnaView = self.qnaView else { return }
      
      qnaView.isCellSelected = isCellSelected
    }
  }

  var delegate: ANIQnaViewDelegate? {
    get { return self.qnaView?.delegate }
    set(v) { self.qnaView?.delegate = v }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = ANIColor.bg
    
    let qnaView = ANIQnaView()
    ANIQnaView.shared = qnaView
    addSubview(qnaView)
    qnaView.edgesToSuperview()
    self.qnaView = qnaView
  }
}

