//
//  ANIInitialView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/23.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import CodableFirebase

protocol ANIInitialViewDelegate {
  func loginSuccess()
  func signUpButtonTapped()
//  func showTerms()
//  func showPrivacyPolicy()
  func reject(notiText: String)
  func startAnimaing()
  func stopAnimating()
}

class ANIInitialView: UIView {
  
  private weak var scrollView: ANIScrollView?
  private weak var contentView: UIView?
  
  private weak var logoImageView: UIImageView?
  
  private weak var loginStackView: UIStackView?
  
  private weak var userIdTitleLabel: UILabel?
  private weak var userIdTextFieldBase: UIView?
  private weak var userIdTextField: UITextField?
  private weak var userIdUnderLineView: UIView?
  
  private weak var passwordTitleLabel: UILabel?
  private weak var passwordTextFieldBase: UIView?
  private weak var passwordTextField: UITextField?
  private weak var passwordUnderLineView: UIView?
  
  private weak var loginButton: ANIAreaButtonView?
  private weak var loginButtonLabel: UILabel?
  
  private weak var signUpButton: ANIAreaButtonView?
  private weak var signUpButtonLabel: UILabel?
  private weak var signUpButtonUnderLineView: UIView?
  
  var myTabBarController: ANITabBarController?
  
  var delegate: ANIInitialViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //scrollView
    let scrollView = ANIScrollView()
    addSubview(scrollView)
    scrollView.edgesToSuperview()
    self.scrollView = scrollView
    
    //contentView
    let contentView = UIView()
    scrollView.addSubview(contentView)
    contentView.edgesToSuperview()
    contentView.width(to: scrollView)
    self.contentView = contentView
    
    //logoImageView
    let logoImageView = UIImageView()
    logoImageView.image = UIImage(named: "logo")
    contentView.addSubview(logoImageView)
    logoImageView.centerXToSuperview()
    logoImageView.topToSuperview(offset: 100.0, usingSafeArea: true)
    logoImageView.width(63.0)
    logoImageView.height(86.0)
    self.logoImageView = logoImageView
    
    //loginStackView
    let loginStackView = UIStackView()
    loginStackView.axis = .vertical
    loginStackView.distribution = .equalSpacing
    loginStackView.spacing = 12.0
    contentView.addSubview(loginStackView)
    loginStackView.topToBottom(of: logoImageView, offset: 78.0)
    loginStackView.leftToSuperview(offset: 40.0)
    loginStackView.rightToSuperview(offset: -40.0)
    self.loginStackView = loginStackView
    
    //userIdTitleLabel
    let userIdTitleLabel = UILabel()
    userIdTitleLabel.text = "ユーザーID"
    userIdTitleLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
    userIdTitleLabel.textColor = ANIColor.darkGray
    userIdTitleLabel.textAlignment = .left
    loginStackView.addArrangedSubview(userIdTitleLabel)
    self.userIdTitleLabel = userIdTitleLabel
    
    //userIdTextFieldBase
    let userIdTextFieldBase = UIView()
    loginStackView.addArrangedSubview(userIdTextFieldBase)
    self.userIdTextFieldBase = userIdTextFieldBase
    
    //userIdTextField
    let userIdTextField = UITextField()
    userIdTextField.font = UIFont.boldSystemFont(ofSize: 16.0)
    userIdTextField.textColor = ANIColor.dark
    userIdTextField.backgroundColor = .clear
    userIdTextField.placeholder = "Diary@diary.com"
    userIdTextField.returnKeyType = .done
    userIdTextField.keyboardType = .emailAddress
    userIdTextFieldBase.addSubview(userIdTextField)
    userIdTextField.edgesToSuperview(excluding: .bottom)
    self.userIdTextField = userIdTextField
    
    //userIdUnderLineView
    let userIdUnderLineView = UIView()
    userIdUnderLineView.backgroundColor = ANIColor.dark
    userIdTextFieldBase.addSubview(userIdUnderLineView)
    userIdUnderLineView.height(1.0)
    userIdUnderLineView.topToBottom(of: userIdTextField, offset: 3.0)
    userIdUnderLineView.edgesToSuperview(excluding: .top)
    self.userIdUnderLineView = userIdUnderLineView
    
    //passwordTitleLabel
    let passwordTitleLabel = UILabel()
    passwordTitleLabel.text = "パスワード"
    passwordTitleLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
    passwordTitleLabel.textColor = ANIColor.darkGray
    passwordTitleLabel.textAlignment = .left
    loginStackView.addArrangedSubview(passwordTitleLabel)
    self.passwordTitleLabel = passwordTitleLabel
    
    //passwordTextFieldBase
    let passwordTextFieldBase = UIView()
    loginStackView.addArrangedSubview(passwordTextFieldBase)
    self.passwordTextFieldBase = passwordTextFieldBase
    
    //passwordTextField
    let passwordTextField = UITextField()
    passwordTextField.font = UIFont.boldSystemFont(ofSize: 16.0)
    passwordTextField.textColor = ANIColor.dark
    passwordTextField.backgroundColor = .clear
    passwordTextField.placeholder = "PASSWORD"
    passwordTextField.returnKeyType = .done
    passwordTextField.isSecureTextEntry = true
    passwordTextFieldBase.addSubview(passwordTextField)
    passwordTextField.edgesToSuperview(excluding: .bottom)
    self.passwordTextField = passwordTextField
    
    //passwordUnderLineView
    let passwordUnderLineView = UIView()
    passwordUnderLineView.backgroundColor = ANIColor.dark
    passwordTextFieldBase.addSubview(passwordUnderLineView)
    passwordUnderLineView.height(1.0)
    passwordUnderLineView.topToBottom(of: passwordTextField, offset: 3.0)
    passwordUnderLineView.edgesToSuperview(excluding: .top)
    self.passwordUnderLineView = passwordUnderLineView
    
    //loginButton
    let loginButton = ANIAreaButtonView()
    loginButton.base?.backgroundColor = .white
    loginButton.base?.layer.borderColor = ANIColor.dark.cgColor
    loginButton.base?.layer.borderWidth = 2.0
    loginButton.delegate = self
    contentView.addSubview(loginButton)
    loginButton.topToBottom(of: loginStackView, offset: 27.0)
    loginButton.height(45.0)
    loginButton.leftToSuperview(offset: 40.0)
    loginButton.rightToSuperview(offset: -40.0)
    self.loginButton = loginButton
    
    //loginButtonLabel
    let loginButtonLabel = UILabel()
    loginButtonLabel.textColor = ANIColor.dark
    loginButtonLabel.textAlignment = .center
    loginButtonLabel.text = "ログイン"
    loginButtonLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
    loginButton.addContent(loginButtonLabel)
    loginButtonLabel.edgesToSuperview()
    self.loginButtonLabel = loginButtonLabel
    
    //signUpButton
    let signUpButton = ANIAreaButtonView()
    signUpButton.base?.backgroundColor = .white
    signUpButton.delegate = self
    contentView.addSubview(signUpButton)
    signUpButton.topToBottom(of: loginButton, offset: 20.0)
    signUpButton.height(20.0)
    signUpButton.centerXToSuperview()
    self.signUpButton = signUpButton
    
    //signUpButtonLabel
    let signUpButtonLabel = UILabel()
    signUpButtonLabel.textColor = ANIColor.darkGray
    signUpButtonLabel.textAlignment = .center
    signUpButtonLabel.text = "アカウント登録"
    signUpButtonLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
    signUpButton.addContent(signUpButtonLabel)
    signUpButtonLabel.edgesToSuperview()
    self.signUpButtonLabel = signUpButtonLabel
    
    //signUpButtonUnderLineView
    let signUpButtonUnderLineView = UIView()
    signUpButtonUnderLineView.backgroundColor = ANIColor.darkGray
    contentView.addSubview(signUpButtonUnderLineView)
    signUpButtonUnderLineView.topToBottom(of: signUpButton, offset: -2.0)
    signUpButtonUnderLineView.left(to: signUpButton, offset: -2.0)
    signUpButtonUnderLineView.right(to: signUpButton, offset: 2.0)
    signUpButtonUnderLineView.height(1.0)
    signUpButtonUnderLineView.bottomToSuperview(offset: -20.0)
    self.signUpButtonUnderLineView = signUpButtonUnderLineView
  }
  
  @objc private func showTerms() {
//    self.delegate?.showTerms()
  }
  
  @objc private func showPrivacyPolicy() {
//    self.delegate?.showPrivacyPolicy()
  }
}

//MARK: ANIButtonViewDelegate
extension ANIInitialView: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === loginButton {
      guard let userIdTextField = self.userIdTextField,
            let userId = userIdTextField.text,
            let passwordTextField = self.passwordTextField,
            let password = passwordTextField.text else { return }
      
      guard userId != "" else {
        self.delegate?.reject(notiText: "ユーザーIDを入力してください")
        return
      }
      
      guard password != "" else {
        self.delegate?.reject(notiText: "パスワードを入力してください")
        return
      }
      
      self.delegate?.startAnimaing()
      
      self.endEditing(true)
      
      Auth.auth().signIn(withEmail: userId, password: password) { (successUser, error) in
        if let errorUnrap = error {
          let nsError = errorUnrap as NSError
          
          self.delegate?.stopAnimating()
          
          DLog("nsError \(nsError)")
          if nsError.code == 17008 || nsError.code == 17011 {
            self.delegate?.reject(notiText: "存在しないメールアドレスです！")
          } else if nsError.code == 17009 {
            self.delegate?.reject(notiText: "パスワードが違います！")
          } else {
            self.delegate?.reject(notiText: "ログインに失敗しました！")
          }
        } else {
          if Auth.auth().currentUser != nil {
            self.myTabBarController?.isLoadedUser = false
            self.myTabBarController?.loadUser() {
              self.delegate?.loginSuccess()
              self.delegate?.stopAnimating()
            }
            
            self.endEditing(true)
          }
        }
      }
    }
    if view === signUpButton {
      self.delegate?.signUpButtonTapped()
    }
  }
}
