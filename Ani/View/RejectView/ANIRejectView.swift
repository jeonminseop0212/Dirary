//
//  ANIRejectView.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/23.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANIRejectView: UIView {
  
  private weak var rejectView: UIView?
  private weak var rejectBaseView: UIView?
  private weak var rejectLabel: UILabel?
  private var isRejectAnimating: Bool = false
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  private func setup() {
    //rejectView
    let rejectView = UIView()
    rejectView.backgroundColor = ANIColor.emerald
    addSubview(rejectView)
    rejectView.edgesToSuperview()
    rejectView.height(UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT)
    self.rejectView = rejectView
    
    //rejectBaseView
    let rejectBaseView = UIView()
    rejectBaseView.backgroundColor = ANIColor.emerald
    rejectView.addSubview(rejectBaseView)
    rejectBaseView.edgesToSuperview(excluding: .top)
    rejectBaseView.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    self.rejectBaseView = rejectBaseView
    
    //rejectLabel
    let rejectLabel = UILabel()
    rejectLabel.textColor = .white
    rejectLabel.textAlignment = .center
    rejectLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
    rejectLabel.textAlignment = .center
    rejectBaseView.addSubview(rejectLabel)
    rejectLabel.edgesToSuperview()
    self.rejectLabel = rejectLabel
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setRejectText(_ text: String) {
    guard let rejectLabel = self.rejectLabel else { return }
    
    rejectLabel.text = text
  }
}
