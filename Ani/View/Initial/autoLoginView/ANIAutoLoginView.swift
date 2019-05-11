//
//  ANIAutoLoginView.swift
//  Ani
//
//  Created by jeonminseop on 2018/10/30.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIAutoLoginViewDelegate {
  func tappeLoginButton()
}

class ANIAutoLoginView: UIView {
  
  private weak var titleLabel: UILabel?
  private weak var introduceLabel: UILabel?
  private let LOGIN_BUTTON_HEIGHT: CGFloat = 45.0
  private weak var loginButton: ANIAreaButtonView?
  private weak var loginButtonLabel: UILabel?
  
  var delegate: ANIAutoLoginViewDelegate?

  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //basic
    self.backgroundColor = .white
    
    //titleLabel
    let titleLabel = UILabel()
    titleLabel.font = UIFont.boldSystemFont(ofSize: 25.0)
    titleLabel.textColor = ANIColor.dark
    titleLabel.text = "登録ありがとうございます😻"
    titleLabel.textAlignment = .center
    self.addSubview(titleLabel)
    titleLabel.topToSuperview(offset: 50.0)
    titleLabel.leftToSuperview(offset: 10.0)
    titleLabel.rightToSuperview(offset: -10.0)
    self.titleLabel = titleLabel
    
    //introduceLabel
    let introduceLabel = UILabel()
    introduceLabel.text = "ログインするにはメールの認証が必要です。\n認証メールをお送りしましたので\n認証後、ログインボタンをクリックしてください。\n\n*承認メールが迷惑メールに入る場合があります*"
    introduceLabel.numberOfLines = 0
    introduceLabel.font = UIFont.systemFont(ofSize: 15.0)
    introduceLabel.textColor = ANIColor.subTitle
    introduceLabel.textAlignment = .center
    self.addSubview(introduceLabel)
    introduceLabel.topToBottom(of: titleLabel, offset: 30.0)
    introduceLabel.leftToSuperview(offset: 10.0)
    introduceLabel.rightToSuperview(offset: -10.0)
    self.introduceLabel = introduceLabel
    
    //loginButton
    let logButton = ANIAreaButtonView()
    logButton.base?.backgroundColor = ANIColor.emerald
    logButton.base?.layer.cornerRadius = LOGIN_BUTTON_HEIGHT / 2
    logButton.delegate = self
    logButton.dropShadow(opacity: 0.1)
    self.addSubview(logButton)
    logButton.topToBottom(of: introduceLabel, offset: 30.0)
    logButton.centerXToSuperview()
    logButton.width(190.0)
    logButton.height(LOGIN_BUTTON_HEIGHT)
    self.loginButton = logButton
    
    //loginButtonLabel
    let loginButtonLabel = UILabel()
    loginButtonLabel.textColor = .white
    loginButtonLabel.text = "ログイン"
    loginButtonLabel.textAlignment = .center
    loginButtonLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
    logButton.addContent(loginButtonLabel)
    loginButtonLabel.edgesToSuperview()
    self.loginButtonLabel = loginButtonLabel
  }
}

extension ANIAutoLoginView: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === self.loginButton {
      self.delegate?.tappeLoginButton()
    }
  }
}
