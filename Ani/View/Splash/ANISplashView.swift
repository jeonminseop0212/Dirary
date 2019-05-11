//
//  ANISplashView.swift
//  Ani
//
//  Created by jeonminseop on 2018/10/31.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANISplashView: UIView {
  
  private weak var backGroundImageView: UIImageView?
  private weak var logoImageView: UIImageView?
  
  weak var activityIndicatorView: ANIActivityIndicator?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //backGroundImageView
    let backGroundImageView = UIImageView()
    backGroundImageView.image = UIImage(named: "splashBG")
    backGroundImageView.contentMode = .scaleAspectFill
    self.addSubview(backGroundImageView)
    backGroundImageView.edgesToSuperview()
    self.backGroundImageView = backGroundImageView
    
    //logoImageView
    let logoImageView = UIImageView()
    logoImageView.image = UIImage(named: "MYAULogo")
    logoImageView.contentMode = .scaleAspectFit
    backGroundImageView.addSubview(logoImageView)
    logoImageView.centerXToSuperview(offset: 5.0)
    logoImageView.centerYToSuperview(offset: -40.0)
    logoImageView.width(100.0)
    self.logoImageView = logoImageView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isSplash = true
    activityIndicatorView.isFull = false
    activityIndicatorView.startAnimating()
    addSubview(activityIndicatorView)
    activityIndicatorView.width(43.0)
    activityIndicatorView.height(35.0)
    activityIndicatorView.topToBottom(of: logoImageView, offset: 50.0)
    activityIndicatorView.centerXToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
}
