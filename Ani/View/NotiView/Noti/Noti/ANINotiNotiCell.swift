//
//  ANINotiNotiCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/14.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANINotiNotiCellDelegate {
  func cellTapped(noti: FirebaseNotification)
}

class ANINotiNotiCell: UICollectionViewCell {
  
  private weak var notiView: ANINotiView?
  
  var isCellSelected: Bool = false {
    didSet {
      guard let notiView = self.notiView else { return }
      
      notiView.isCellSelected = isCellSelected
    }
  }
  
  var delegate: ANINotiNotiCellDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    let notiView = ANINotiView()
    notiView.delegate = self
    ANINotiView.shared = notiView
    addSubview(notiView)
    notiView.edgesToSuperview()
    self.notiView = notiView
  }
}

//MARK: ANINotiViewDelegate
extension ANINotiNotiCell: ANINotiViewDelegate {
  func cellTapped(noti: FirebaseNotification) {
    self.delegate?.cellTapped(noti: noti)
  }
}
