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
  func prifileImagePickButtonTapped()
  func reject(notiText: String)
  func signUpSuccess(adress: String, password: String, userId: String)
  func startAnimaing()
  func stopAnimating()
}

class ANISignUpView: UIView {
  
  private weak var scrollView: ANIScrollView?
  private weak var contentView: UIView?
  
  private let CONTENT_SPACE: CGFloat = 25.0
  
  private let PROFILE_IMAGE_VIEW_HEIGHT: CGFloat = 110.0
  private weak var profileImageView: UIImageView?
  private let PROFILE_IMAGE_PICK_BUTTON_HEIGHT: CGFloat = 30.0
  private weak var profileImagePickButton: ANIImageButtonView?
  
  private weak var adressTitleLabel: UILabel?
  private weak var adressDescriptionLabel: UILabel?
  private weak var adressTextFieldBG: UIView?
  private weak var adressTextField: UITextField?
  
  private weak var passwordTitleLabel: UILabel?
  private weak var passwordTextFieldBG: UIView?
  private weak var passwordTextField: UITextField?
  private weak var passwordCheckTextFieldBG: UIView?
  private weak var passwordCheckTextField: UITextField?
  
  private weak var userNameTitleLabel: UILabel?
  private weak var userNameTextFieldBG: UIView?
  private weak var userNameTextField: UITextField?
  
  private let DONE_BUTTON_HEIGHT: CGFloat = 45.0
  private weak var doneButton: ANIAreaButtonView?
  private weak var doneButtonLabel: UILabel?
  
  private var selectedTextFieldMaxY: CGFloat?
  
  private var user: User?
  var profileImage: UIImage? {
    didSet {
      guard let profileImageView = self.profileImageView,
            let profileImage = self.profileImage else { return }
      
      profileImageView.image = profileImage
    }
  }
  
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
    
    //profileImageView
    let profileImageView = UIImageView()
    profileImageView.contentMode = .scaleAspectFill
    profileImageView.layer.cornerRadius = PROFILE_IMAGE_VIEW_HEIGHT / 2
    profileImageView.layer.masksToBounds = true
    contentView.addSubview(profileImageView)
    profileImageView.topToSuperview(offset: 10.0)
    profileImageView.width(PROFILE_IMAGE_VIEW_HEIGHT)
    profileImageView.height(PROFILE_IMAGE_VIEW_HEIGHT)
    profileImageView.centerXToSuperview()
    self.profileImageView = profileImageView
    profileImage = UIImage(named: "profileDefaultImage")
    
    //profileImagePickButton
    let profileImagePickButton = ANIImageButtonView()
    profileImagePickButton.image = UIImage(named: "imagePickButton")
    profileImagePickButton.delegate = self
    contentView.addSubview(profileImagePickButton)
    profileImagePickButton.width(PROFILE_IMAGE_PICK_BUTTON_HEIGHT)
    profileImagePickButton.height(PROFILE_IMAGE_PICK_BUTTON_HEIGHT)
    profileImagePickButton.bottom(to: profileImageView)
    profileImagePickButton.right(to: profileImageView)
    self.profileImagePickButton = profileImagePickButton
    
    //adressTitleLabel
    let adressTitleLabel = UILabel()
    adressTitleLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
    adressTitleLabel.textColor = ANIColor.dark
    adressTitleLabel.text = "IDを決めましょう！"
    contentView.addSubview(adressTitleLabel)
    adressTitleLabel.topToBottom(of: profileImageView, offset: CONTENT_SPACE)
    adressTitleLabel.leftToSuperview(offset: 10.0)
    self.adressTitleLabel = adressTitleLabel
    
    //adressDescriptionLabel
    let adressDescriptionLabel = UILabel()
    adressDescriptionLabel.font = UIFont.boldSystemFont(ofSize: 13.0)
    adressDescriptionLabel.textColor = ANIColor.moreDarkGray
    adressDescriptionLabel.text = "(メールアドレス)"
    contentView.addSubview(adressDescriptionLabel)
    adressDescriptionLabel.bottom(to: adressTitleLabel, offset: -2.0)
    adressDescriptionLabel.leftToRight(of: adressTitleLabel)
    self.adressDescriptionLabel = adressDescriptionLabel
    
    //adressTextFieldBG
    let adressTextFieldBG = UIView()
    adressTextFieldBG.backgroundColor = ANIColor.lightGray
    adressTextFieldBG.layer.cornerRadius = 10.0
    adressTextFieldBG.layer.masksToBounds = true
    contentView.addSubview(adressTextFieldBG)
    adressTextFieldBG.topToBottom(of: adressTitleLabel, offset: 10.0)
    adressTextFieldBG.leftToSuperview(offset: 10.0)
    adressTextFieldBG.rightToSuperview(offset: -10.0)
    self.adressTextFieldBG = adressTextFieldBG
    
    //adressTextField
    let adressTextField = UITextField()
    adressTextField.font = UIFont.systemFont(ofSize: 18.0)
    adressTextField.textColor = ANIColor.dark
    adressTextField.backgroundColor = .clear
    adressTextField.placeholder = "ex)MYAU@myau.com"
    adressTextField.returnKeyType = .done
    adressTextField.keyboardType = .emailAddress
    adressTextField.delegate = self
    adressTextFieldBG.addSubview(adressTextField)
    let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    adressTextField.edgesToSuperview(insets: insets)
    self.adressTextField = adressTextField
    
    //passwordTitleLabel
    let passwordTitleLabel = UILabel()
    passwordTitleLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
    passwordTitleLabel.textColor = ANIColor.dark
    passwordTitleLabel.text = "パスワードを決めましょう🔑"
    contentView.addSubview(passwordTitleLabel)
    passwordTitleLabel.topToBottom(of: adressTextFieldBG, offset: CONTENT_SPACE)
    passwordTitleLabel.leftToSuperview(offset: 10.0)
    passwordTitleLabel.rightToSuperview(offset: -10.0)
    self.passwordTitleLabel = passwordTitleLabel
    
    //passwordTextFieldBG
    let passwordTextFieldBG = UIView()
    passwordTextFieldBG.backgroundColor = ANIColor.lightGray
    passwordTextFieldBG.layer.cornerRadius = 10.0
    passwordTextFieldBG.layer.masksToBounds = true
    contentView.addSubview(passwordTextFieldBG)
    passwordTextFieldBG.topToBottom(of: passwordTitleLabel, offset: 10.0)
    passwordTextFieldBG.leftToSuperview(offset: 10.0)
    passwordTextFieldBG.rightToSuperview(offset: -10.0)
    self.passwordTextFieldBG = passwordTextFieldBG
    
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
    passwordTextField.edgesToSuperview(insets: insets)
    self.passwordTextField = passwordTextField
    
    //passwordCheckTextFieldBG
    let passwordCheckTextFieldBG = UIView()
    passwordCheckTextFieldBG.backgroundColor = ANIColor.lightGray
    passwordCheckTextFieldBG.layer.cornerRadius = 10.0
    passwordCheckTextFieldBG.layer.masksToBounds = true
    contentView.addSubview(passwordCheckTextFieldBG)
    passwordCheckTextFieldBG.topToBottom(of: passwordTextFieldBG, offset: 10.0)
    passwordCheckTextFieldBG.leftToSuperview(offset: 10.0)
    passwordCheckTextFieldBG.rightToSuperview(offset: -10.0)
    self.passwordCheckTextFieldBG = passwordCheckTextFieldBG
    
    //passwordCheckTextField
    let passwordCheckTextField = UITextField()
    passwordCheckTextField.font = UIFont.systemFont(ofSize: 18.0)
    passwordCheckTextField.textColor = ANIColor.dark
    passwordCheckTextField.backgroundColor = .clear
    passwordCheckTextField.placeholder = "パスワードの確認"
    passwordCheckTextField.returnKeyType = .done
    passwordCheckTextField.isSecureTextEntry = true
    passwordCheckTextField.delegate = self
    passwordCheckTextFieldBG.addSubview(passwordCheckTextField)
    passwordCheckTextField.edgesToSuperview(insets: insets)
    self.passwordCheckTextField = passwordCheckTextField
    
    //userNameTitleLabel
    let userNameTitleLabel = UILabel()
    userNameTitleLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
    userNameTitleLabel.textColor = ANIColor.dark
    userNameTitleLabel.text = "ユーザーネームを決めましょう！"
    contentView.addSubview(userNameTitleLabel)
    userNameTitleLabel.topToBottom(of: passwordCheckTextFieldBG, offset: CONTENT_SPACE)
    userNameTitleLabel.leftToSuperview(offset: 10.0)
    userNameTitleLabel.rightToSuperview(offset: -10.0)
    self.userNameTitleLabel = userNameTitleLabel
    
    //userNameTextFieldBG
    let userNameTextFieldBG = UIView()
    userNameTextFieldBG.backgroundColor = ANIColor.lightGray
    userNameTextFieldBG.layer.cornerRadius = 10.0
    userNameTextFieldBG.layer.masksToBounds = true
    contentView.addSubview(userNameTextFieldBG)
    userNameTextFieldBG.topToBottom(of: userNameTitleLabel, offset: 10.0)
    userNameTextFieldBG.leftToSuperview(offset: 10.0)
    userNameTextFieldBG.rightToSuperview(offset: -10.0)
    self.userNameTextFieldBG = userNameTextFieldBG
    
    //userNameTextField
    let userNameTextField = UITextField()
    userNameTextField.font = UIFont.systemFont(ofSize: 18.0)
    userNameTextField.textColor = ANIColor.dark
    userNameTextField.backgroundColor = .clear
    userNameTextField.placeholder = "ex)MYAU-myau"
    userNameTextField.returnKeyType = .done
    userNameTextField.delegate = self
    userNameTextFieldBG.addSubview(userNameTextField)
    userNameTextField.edgesToSuperview(insets: insets)
    self.userNameTextField = userNameTextField
    
    //doneButton
    let doneButton = ANIAreaButtonView()
    doneButton.base?.backgroundColor = ANIColor.emerald
    doneButton.base?.layer.cornerRadius = DONE_BUTTON_HEIGHT / 2
    doneButton.delegate = self
    doneButton.dropShadow(opacity: 0.1)
    contentView.addSubview(doneButton)
    doneButton.topToBottom(of: userNameTextFieldBG, offset: CONTENT_SPACE)
    doneButton.centerXToSuperview()
    doneButton.width(190.0)
    doneButton.height(DONE_BUTTON_HEIGHT)
    doneButton.bottomToSuperview(offset: -10.0)
    self.doneButton = doneButton
    
    //doneButtonLabel
    let doneButtonLabel = UILabel()
    doneButtonLabel.textColor = .white
    doneButtonLabel.text = "OK!"
    doneButtonLabel.textAlignment = .center
    doneButtonLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
    doneButton.addContent(doneButtonLabel)
    doneButtonLabel.edgesToSuperview()
    self.doneButtonLabel = doneButtonLabel
  }
  
  private func setupNotifications() {
    ANINotificationManager.receive(keyboardWillChangeFrame: self, selector: #selector(keyboardWillChangeFrame))
  }
  
  private func signUp(adress: String, password: String) {
    guard let userNameTextField = self.userNameTextField,
          let userName = userNameTextField.text else { return }
    
    self.delegate?.startAnimaing()
    
    let database = Firestore.firestore()
    DispatchQueue.global().async {
      database.collection(KEY_USERS).whereField(KEY_USER_NAME, isEqualTo: userName).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        if snapshot.documents.isEmpty {
          self.createAccount(adress: adress, password: password)
        } else {
          self.delegate?.stopAnimating()

          self.delegate?.reject(notiText: "すでに存在するユーザーネームです！")
        }
      })
    }
  }
  
  private func createAccount(adress: String, password: String) {
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
        Auth.auth().languageCode = "ja"
        Auth.auth().currentUser?.sendEmailVerification(completion: { (error) in
          if let error = error {
            DLog("send email verification error \(error)")
            self.delegate?.reject(notiText: "認証メールの送信に失敗しました")
            return
          }
          
          self.adress = adress
          self.password = password
          self.uploadUserData()
        })
      }
    }
  }
  
  
  private func uploadUserData() {
    guard let currentUser = Auth.auth().currentUser,
          let profileImage = self.profileImage,
          let profileImageData = profileImage.jpegData(compressionQuality: 0.5),
          let userNameTextField = self.userNameTextField,
          let userName = userNameTextField.text else { return }

    let storageRef = Storage.storage().reference()
    storageRef.child(KEY_PROFILE_IMAGES).child("\(currentUser.uid).jpeg").putData(profileImageData, metadata: nil) { (metaData, error) in
      if error != nil {
        DLog("storageError")
        self.delegate?.stopAnimating()
        return
      }
      
      storageRef.child(KEY_PROFILE_IMAGES).child("\(currentUser.uid).jpeg").downloadURL(completion: { (url, error) in
        if error != nil {
          DLog("storage download url error")
          return
        }
        
        if let profileImageUrl = url {
          let fcmToken = UserDefaults.standard.string(forKey: KEY_FCM_TOKEN)
          let user = FirebaseUser(uid: currentUser.uid, userName: userName, kind: "個人", introduce: "", profileImageUrl: profileImageUrl.absoluteString, familyImageUrls: nil, checkNotiDate: nil, isHaveUnreadNoti: false, unreadNotiCount: 0, unreadMessageCount: 0, fcmToken: fcmToken, twitterAccount: nil, instagramAccount: nil, isTwitterLink: false)
          self.uploadUserIntoDatabase(uid: currentUser.uid, user: user)
        }
      })
    }
  }
  
  private func uploadUserIntoDatabase(uid: String, user: FirebaseUser) {
    let database = Firestore.firestore()
    
    do {
      let userData = try FirestoreEncoder().encode(user)
      
      database.collection(KEY_USERS).document(uid).setData(userData) { error in
        if let error = error {
          DLog("Error set document: \(error)")
          return
        }
        
        self.delegate?.signUpSuccess(adress: self.adress, password: self.password, userId: uid)
        
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
    if view == profileImagePickButton {
      self.delegate?.prifileImagePickButtonTapped()
    }
    if view == doneButton {
      guard let adressTextField = self.adressTextField,
            let adress = adressTextField.text,
            let passwordTextField = self.passwordTextField,
            let password = passwordTextField.text,
            let passwordCheckTextField = self.passwordCheckTextField,
            let passwordCheck = passwordCheckTextField.text,
            let userNameTextField = self.userNameTextField,
            let userName = userNameTextField.text else { return }
      
      if adress.count > 0 && password.count > 0 && passwordCheck.count > 0 && userName.count > 0 {
        if password == passwordCheck {
          signUp(adress: adress, password: password)
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
