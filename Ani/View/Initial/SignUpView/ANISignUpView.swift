//
//  SignUpView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/24.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import CodableFirebase

protocol ANISignUpViewDelegate {
  func reject(notiText: String)
  func signUpSuccess()
  func startAnimaing()
  func stopAnimating()
}

class ANISignUpView: UIView {
  
  private weak var scrollView: ANIScrollView?
  private weak var contentView: UIView?
  
  private weak var signUpStackView: UIStackView?
  
  private weak var userIdTitleLabel: UILabel?
  private weak var userIdTextFieldBase: UIView?
  private weak var userIdTextField: UITextField?
  private weak var userIdUnderLineView: UIView?
  
  private weak var passwordTitleLabel: UILabel?
  private weak var passwordTextFieldBase: UIView?
  private weak var passwordTextField: UITextField?
  private weak var passwordUnderLineView: UIView?
  
  private weak var passwordCheckTitleLabel: UILabel?
  private weak var passwordCheckTextFieldBase: UIView?
  private weak var passwordCheckTextField: UITextField?
  private weak var passwordCheckUnderLineView: UIView?
  
  private let DONE_BUTTON_HEIGHT: CGFloat = 45.0
  private weak var doneButton: ANIAreaButtonView?
  private weak var doneButtonLabel: UILabel?
  
  private var selectedTextFieldMaxY: CGFloat?
  
  private var user: User?
  
  private var adress: String = ""
  private var password: String = ""
  
  var delegate: ANISignUpViewDelegate?
  
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
    
    //signUpStackView
    let signUpStackView = UIStackView()
    signUpStackView.axis = .vertical
    signUpStackView.distribution = .equalSpacing
    signUpStackView.spacing = 12.0
    contentView.addSubview(signUpStackView)
    signUpStackView.topToSuperview(offset: 100.0, usingSafeArea: true)
    signUpStackView.leftToSuperview(offset: 40.0)
    signUpStackView.rightToSuperview(offset: -40.0)
    self.signUpStackView = signUpStackView
    
    //userIdTitleLabel
    let userIdTitleLabel = UILabel()
    userIdTitleLabel.text = "ユーザーID"
    userIdTitleLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
    userIdTitleLabel.textColor = ANIColor.darkGray
    userIdTitleLabel.textAlignment = .left
    signUpStackView.addArrangedSubview(userIdTitleLabel)
    self.userIdTitleLabel = userIdTitleLabel
    
    //userIdTextFieldBase
    let userIdTextFieldBase = UIView()
    signUpStackView.addArrangedSubview(userIdTextFieldBase)
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
    signUpStackView.addArrangedSubview(passwordTitleLabel)
    self.passwordTitleLabel = passwordTitleLabel
    
    //passwordTextFieldBase
    let passwordTextFieldBase = UIView()
    signUpStackView.addArrangedSubview(passwordTextFieldBase)
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
    
    //passwordCheckTitleLabel
    let passwordCheckTitleLabel = UILabel()
    passwordCheckTitleLabel.text = "パスワード確認"
    passwordCheckTitleLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
    passwordCheckTitleLabel.textColor = ANIColor.darkGray
    passwordCheckTitleLabel.textAlignment = .left
    signUpStackView.addArrangedSubview(passwordCheckTitleLabel)
    self.passwordCheckTitleLabel = passwordCheckTitleLabel
    
    //passwordCheckTextFieldBase
    let passwordCheckTextFieldBase = UIView()
    signUpStackView.addArrangedSubview(passwordCheckTextFieldBase)
    self.passwordCheckTextFieldBase = passwordCheckTextFieldBase
    
    //passwordCheckTextField
    let passwordCheckTextField = UITextField()
    passwordCheckTextField.font = UIFont.boldSystemFont(ofSize: 16.0)
    passwordCheckTextField.textColor = ANIColor.dark
    passwordCheckTextField.backgroundColor = .clear
    passwordCheckTextField.placeholder = "PASSWORD"
    passwordCheckTextField.returnKeyType = .done
    passwordCheckTextField.isSecureTextEntry = true
    passwordCheckTextFieldBase.addSubview(passwordCheckTextField)
    passwordCheckTextField.edgesToSuperview(excluding: .bottom)
    self.passwordCheckTextField = passwordCheckTextField
    
    //passwordCheckUnderLineView
    let passwordCheckUnderLineView = UIView()
    passwordCheckUnderLineView.backgroundColor = ANIColor.dark
    passwordCheckTextFieldBase.addSubview(passwordCheckUnderLineView)
    passwordCheckUnderLineView.height(1.0)
    passwordCheckUnderLineView.topToBottom(of: passwordCheckTextField, offset: 3.0)
    passwordCheckUnderLineView.edgesToSuperview(excluding: .top)
    self.passwordCheckUnderLineView = passwordCheckUnderLineView
    
    //doneButton
    let doneButton = ANIAreaButtonView()
    doneButton.base?.backgroundColor = .white
    doneButton.base?.layer.borderColor = ANIColor.dark.cgColor
    doneButton.base?.layer.borderWidth = 2.0
    doneButton.delegate = self
    contentView.addSubview(doneButton)
    doneButton.topToBottom(of: signUpStackView, offset: 27.0)
    doneButton.height(45.0)
    doneButton.leftToSuperview(offset: 40.0)
    doneButton.rightToSuperview(offset: -40.0)
    doneButton.bottomToSuperview(offset: -20.0)
    self.doneButton = doneButton
    
    //doneButtonLabel
    let doneButtonLabel = UILabel()
    doneButtonLabel.textColor = ANIColor.dark
    doneButtonLabel.textAlignment = .center
    doneButtonLabel.text = "OK!"
    doneButtonLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
    doneButton.addContent(doneButtonLabel)
    doneButtonLabel.edgesToSuperview()
    self.doneButtonLabel = doneButtonLabel
  }
  
  private func setupNotifications() {
    ANINotificationManager.receive(keyboardWillChangeFrame: self, selector: #selector(keyboardWillChangeFrame))
  }
  
  private func createAccount(adress: String, password: String) {
    self.delegate?.startAnimaing()

    Auth.auth().createUser(withEmail: adress, password: password) { (successUser, error) in
      if let errorUnrap = error {
        let nsError = errorUnrap as NSError
        
        self.delegate?.stopAnimating()

        if nsError.code == 17007 {
          self.delegate?.reject(notiText: "すでに存在するメールアドレスです！")
        } else if nsError.code == 17008 {
          self.delegate?.reject(notiText: "メールアドレスの書式が正しくありません！")
        } else if nsError.code == 17026 {
          self.delegate?.reject(notiText: "パスワードが６文字未満です！")
        } else {
          self.delegate?.reject(notiText: "登録に失敗しました！")
        }
      } else {
        self.adress = adress
        self.password = password
        self.uploadUserData()
      }
    }
  }
  
  
  private func uploadUserData() {
    guard let currentUser = Auth.auth().currentUser else { return }
    
    let database = Firestore.firestore()
    
    let user = FirebaseUser(uid: currentUser.uid, createdAt: ANIFunction.shared.getToday())
    
    do {
      let userData = try FirestoreEncoder().encode(user)
      
      database.collection(KEY_USERS).document(currentUser.uid).setData(userData) { error in
        if let error = error {
          DLog("Error set document: \(error)")
          return
        }
        
        self.delegate?.signUpSuccess()
        
        self.delegate?.stopAnimating()
      }
      
      self.endEditing(true)
    } catch let error {
      DLog(error)
      self.delegate?.stopAnimating()
    }
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
extension ANISignUpView: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view == doneButton {
      guard let userIdTextField = self.userIdTextField,
            let userId = userIdTextField.text,
            let passwordTextField = self.passwordTextField,
            let password = passwordTextField.text,
            let passwordCheckTextField = self.passwordCheckTextField,
            let passwordCheck = passwordCheckTextField.text else { return }
      
      if userId.count > 0 && password.count > 0 && passwordCheck.count > 0 {
        if password == passwordCheck {
          createAccount(adress: userId, password: password)
          self.endEditing(true)
        } else {
          self.delegate?.reject(notiText: "パスワードが異なります！")
        }
      } else {
        self.delegate?.reject(notiText: "入力していない項目があります！")
      }
    }
  }
}

//MARK: UITextFieldDelegate
extension ANISignUpView: UITextFieldDelegate {
  func textFieldDidBeginEditing(_ textField: UITextField) {
    guard let selectedTextViewSuperView = textField.superview else { return }
    selectedTextFieldMaxY = selectedTextViewSuperView.frame.maxY + UIViewController.STATUS_BAR_HEIGHT + UIViewController.NAVIGATION_BAR_HEIGHT
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.endEditing(true)
    
    return true
  }
}
