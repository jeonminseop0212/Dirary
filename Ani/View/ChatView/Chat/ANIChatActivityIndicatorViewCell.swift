
//
//  ANIChatActivityIndicatorViewCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/10/04.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class ANIChatActivityIndicatorViewCell: UITableViewCell {
  
  private weak var base: UIView?
  private weak var activityIndicatorView: NVActivityIndicatorView?
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //base
    let base = UIView()
    base.backgroundColor = .white
    addSubview(base)
    base.edgesToSuperview()
    base.height(30.0)
    self.base = base
    
    //activityIndicatorView
    let activityIndicatorView = NVActivityIndicatorView(frame: .zero, type: .ballSpinFadeLoader, color: ANIColor.moreDarkGray, padding: 0)
    activityIndicatorView.startAnimating()
    base.addSubview(activityIndicatorView)
    activityIndicatorView.width(25.0)
    activityIndicatorView.height(25.0)
    activityIndicatorView.topToSuperview()
    activityIndicatorView.centerXToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
}
