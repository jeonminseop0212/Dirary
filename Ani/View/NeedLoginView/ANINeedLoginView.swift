//
//  ANINeedLoginView.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/24.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANINeedLoginViewDelegate {
  func loginButtonTapped()
}

class ANINeedLoginView: UIView {
  
  private weak var messageLabel: UILabel?
  
  private let LOGIN_BUTTON_HEIGHT: CGFloat = 45.0
  private let LOGIN_BUTTON_WIDTH: CGFloat = 160.0
  private weak var loginButton: ANIAreaButtonView?
  private weak var loginButtonLabel: UILabel?
  
  var delegate: ANINeedLoginViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = .white
    
    //messageLabel
    let messageLabel = UILabel()
    messageLabel.textColor = ANIColor.dark
    messageLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
    messageLabel.numberOfLines = 0
    messageLabel.textAlignment = .center
    addSubview(messageLabel)
    messageLabel.centerXToSuperview()
    messageLabel.centerYToSuperview(offset: -30.0)
    self.messageLabel = messageLabel
    
    //loginButton
    let loginButton = ANIAreaButtonView()
    loginButton.base?.backgroundColor = ANIColor.emerald
    loginButton.baseCornerRadius = LOGIN_BUTTON_HEIGHT / 2
    loginButton.dropShadow(opacity: 0.1)
    loginButton.delegate = self
    self.addSubview(loginButton)
    loginButton.topToBottom(of: messageLabel, offset: 30.0)
    loginButton.centerXToSuperview()
    loginButton.height(LOGIN_BUTTON_HEIGHT)
    loginButton.width(LOGIN_BUTTON_WIDTH)
    self.loginButton = loginButton
    
    //loginButtonLabel
    let loginButtonLabel = UILabel()
    loginButtonLabel.text = "ログインする"
    loginButtonLabel.textAlignment = .center
    loginButtonLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
    loginButtonLabel.textColor = .white
    loginButton.addContent(loginButtonLabel)
    loginButtonLabel.edgesToSuperview()
    self.loginButtonLabel = loginButtonLabel
  }
  
  func setupMessage(text: String) {
    guard let messageLabel = self.messageLabel else { return }
    
    messageLabel.text = text
  }
}

//MARK: ANIButtonViewDelegate
extension ANINeedLoginView: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === loginButton {
      self.delegate?.loginButtonTapped()
    }
  }
}
