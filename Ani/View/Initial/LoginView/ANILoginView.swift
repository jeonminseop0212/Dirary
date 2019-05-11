//
//  ANILoginView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/23.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import CodableFirebase

protocol ANILoginViewDelegate {
  func reject(notiText: String)
  func loginSuccess()
  func startAnimaing()
  func stopAnimating()
}

class ANILoginView: UIView {
  
  private weak var scrollView: ANIScrollView?
  private weak var contentView: UIView?
  
  private weak var titleLabel: UILabel?
  private weak var emailTextFieldBG: UIView?
  private weak var emailImageView: UIImageView?
  private weak var emailTextField: UITextField?
  
  private weak var passwordTextFieldBG: UIView?
  private weak var passwordImageView: UIImageView?
  private weak var passwordTextField: UITextField?
  
  private let LOGIN_BUTTON_HEIGHT: CGFloat = 45.0
  private weak var loginButton: ANIAreaButtonView?
  private weak var loginButtonLabel: UILabel?
  
  private var selectedTextFieldMaxY: CGFloat?
  
  var myTabBarController: ANITabBarController?
  
  var delegate: ANILoginViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
    setupNotifications()
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
    
    //titleLabel
    let titleLabel = UILabel()
    titleLabel.font = UIFont.boldSystemFont(ofSize: 30.0)
    titleLabel.textColor = ANIColor.dark
    titleLabel.text = "おかえりなさい😻"
    titleLabel.textAlignment = .center
    contentView.addSubview(titleLabel)
    titleLabel.topToSuperview(offset: 50.0)
    titleLabel.leftToSuperview(offset: 10.0)
    titleLabel.rightToSuperview(offset: -10.0)
    self.titleLabel = titleLabel
    
    //emailTextFieldBG
    let emailTextFieldBG = UIView()
    emailTextFieldBG.backgroundColor = ANIColor.lightGray
    emailTextFieldBG.layer.cornerRadius = 10.0
    emailTextFieldBG.layer.masksToBounds = true
    contentView.addSubview(emailTextFieldBG)
    emailTextFieldBG.topToBottom(of: titleLabel, offset: 30.0)
    emailTextFieldBG.leftToSuperview(offset: 10.0)
    emailTextFieldBG.rightToSuperview(offset: -10.0)
    self.emailTextFieldBG = emailTextFieldBG
    
    //emailImageView
    let emailImageView = UIImageView()
    emailImageView.image = UIImage(named: "idImage")
    emailTextFieldBG.addSubview(emailImageView)
    emailImageView.width(19.0)
    emailImageView.height(18.0)
    emailImageView.leftToSuperview(offset: 10.0)
    emailImageView.centerYToSuperview()
    self.emailImageView = emailImageView
    
    //emailTextField
    let emailTextField = UITextField()
    emailTextField.font = UIFont.systemFont(ofSize: 18.0)
    emailTextField.textColor = ANIColor.dark
    emailTextField.backgroundColor = .clear
    emailTextField.placeholder = "IDまたはユーザーネーム"
    emailTextField.returnKeyType = .done
    emailTextField.keyboardType = .emailAddress
    emailTextField.delegate = self
    emailTextFieldBG.addSubview(emailTextField)
    let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    emailTextField.edgesToSuperview(excluding: .left, insets: insets)
    emailTextField.leftToRight(of: emailImageView, offset: 10.0)
    self.emailTextField = emailTextField
    
    //passwordTextFieldBG
    let passwordTextFieldBG = UIView()
    passwordTextFieldBG.backgroundColor = ANIColor.lightGray
    passwordTextFieldBG.layer.cornerRadius = 10.0
    passwordTextFieldBG.layer.masksToBounds = true
    contentView.addSubview(passwordTextFieldBG)
    passwordTextFieldBG.topToBottom(of: emailTextFieldBG, offset: 20.0)
    passwordTextFieldBG.leftToSuperview(offset: 10.0)
    passwordTextFieldBG.rightToSuperview(offset: -10.0)
    self.passwordTextFieldBG = passwordTextFieldBG

    //passwordImageView
    let passwordImageView = UIImageView()
    passwordImageView.image = UIImage(named: "passwordImage")
    passwordTextFieldBG.addSubview(passwordImageView)
    passwordImageView.width(15.0)
    passwordImageView.height(20.0)
    passwordImageView.centerX(to: emailImageView)
    passwordImageView.centerYToSuperview()
    self.passwordImageView = passwordImageView
    
    //passwordTextField
    let passwordTextField = UITextField()
    passwordTextField.font = UIFont.systemFont(ofSize: 18.0)
    passwordTextField.textColor = ANIColor.dark
    passwordTextField.backgroundColor = .clear
    passwordTextField.placeholder = "パスワード"
    passwordTextField.returnKeyType = .done
    passwordTextField.isSecureTextEntry = true
    passwordTextField.delegate = self
    passwordTextFieldBG.addSubview(passwordTextField)
    passwordTextField.edgesToSuperview(excluding: .left, insets: insets)
    passwordTextField.left(to: emailTextField)
    self.passwordTextField = passwordTextField
    
    //loginButton
    let logButton = ANIAreaButtonView()
    logButton.base?.backgroundColor = ANIColor.emerald
    logButton.base?.layer.cornerRadius = LOGIN_BUTTON_HEIGHT / 2
    logButton.delegate = self
    logButton.dropShadow(opacity: 0.1)
    contentView.addSubview(logButton)
    logButton.topToBottom(of: passwordTextFieldBG, offset: 30.0)
    logButton.centerXToSuperview()
    logButton.width(190.0)
    logButton.height(LOGIN_BUTTON_HEIGHT)
    logButton.bottomToSuperview(offset: -10)
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
  
  private func setupNotifications() {
    ANINotificationManager.receive(keyboardWillChangeFrame: self, selector: #selector(keyboardWillChangeFrame))
  }
  
  @objc func keyboardWillChangeFrame(_ notification: Notification) {
    guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
      let scrollView = self.scrollView,
      let selectedTextFieldMaxY = self.selectedTextFieldMaxY else { return }
    
    let selectedTextFieldVisiableMaxY = selectedTextFieldMaxY - scrollView.contentOffset.y
    
    if selectedTextFieldVisiableMaxY > keyboardFrame.origin.y {
      let margin: CGFloat = 10.0
      let blindHeight = selectedTextFieldVisiableMaxY - keyboardFrame.origin.y + margin
      scrollView.contentOffset.y = scrollView.contentOffset.y + blindHeight
    }
  }
}

//MARK: ANIButtonViewDelegate
extension ANILoginView: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === loginButton {
      guard let emailTextField = self.emailTextField,
            let email = emailTextField.text,
            let passwordTextField = self.passwordTextField,
            let password = passwordTextField.text else { return }
      
      self.delegate?.startAnimaing()
      
      self.endEditing(true)
      
      Auth.auth().signIn(withEmail: email, password: password) { (successUser, error) in
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
          if let currentUser = Auth.auth().currentUser {
            if currentUser.isEmailVerified {
              self.myTabBarController?.isLoadedUser = false
              self.myTabBarController?.isLoadedFirstData = false
              self.myTabBarController?.loadUser() {
                self.delegate?.loginSuccess()
                self.myTabBarController?.observeChatGroup()
                
                self.delegate?.stopAnimating()
              }
            } else {
              self.delegate?.stopAnimating()
              
              self.delegate?.reject(notiText: "アドレスの認証メールを確認してください！")
            }
            
            self.endEditing(true)
          }
        }
      }
    }
  }
}

//MARK: UITextFieldDelegate
extension ANILoginView: UITextFieldDelegate {
  func textFieldDidBeginEditing(_ textField: UITextField) {
    guard let selectedTextViewSuperView = textField.superview else { return }
    selectedTextFieldMaxY = selectedTextViewSuperView.frame.maxY + UIViewController.STATUS_BAR_HEIGHT + UIViewController.NAVIGATION_BAR_HEIGHT
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.endEditing(true)
    
    return true
  }
}
