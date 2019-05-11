//
//  ANIOpinionBoxView.swift
//  Ani
//
//  Created by jeonminseop on 2018/10/29.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase

protocol ANIOpinionBoxViewDelegate {
  func didPostOpinion()
}

class ANIOpinionBoxView: UIView {
  
  private weak var anonymousTitleLabel: UILabel?
  private let BUTTON_HEIGHT: CGFloat = 30.0
  private weak var anonymousPostButton: ANIAreaButtonView?
  private weak var anonymousPostButtonLabel: UILabel?
  private weak var anonymousOpinionTextViewBG: UIView?
  private weak var anonymousOpinionTextView: ANIPlaceHolderTextView?

  private let KEYBOARD_HIDE_TOOL_BAR_HEIGHT: CGFloat = 40.0
  
  var chatGroup: FirebaseChatGroup?
  var adminUser: FirebaseUser?
  
  var delegate: ANIOpinionBoxViewDelegate?
  
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
    
    //anonymousPostButton
    let anonymousPostButton = ANIAreaButtonView()
    anonymousPostButton.base?.backgroundColor = ANIColor.emerald
    anonymousPostButton.baseCornerRadius = BUTTON_HEIGHT / 2
    anonymousPostButton.delegate = self
    self.addSubview(anonymousPostButton)
    anonymousPostButton.rightToSuperview(offset: -10.0)
    anonymousPostButton.topToSuperview(offset: 10.0)
    anonymousPostButton.height(BUTTON_HEIGHT)
    anonymousPostButton.width(60.0)
    self.anonymousPostButton = anonymousPostButton
    
    //anonymousPostButtonLabel
    let anonymousPostButtonLabel = UILabel()
    anonymousPostButtonLabel.textColor = .white
    anonymousPostButtonLabel.text = "送信"
    anonymousPostButtonLabel.textAlignment = .center
    anonymousPostButtonLabel.font = UIFont.boldSystemFont(ofSize: 15)
    anonymousPostButton.addContent(anonymousPostButtonLabel)
    anonymousPostButtonLabel.edgesToSuperview()
    self.anonymousPostButtonLabel = anonymousPostButtonLabel
    
    //anonymousTitleLabel
    let anonymousTitleLabel = UILabel()
    anonymousTitleLabel.text = "匿名で意見を送る"
    anonymousTitleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
    anonymousTitleLabel.textColor = ANIColor.dark
    self.addSubview(anonymousTitleLabel)
    anonymousTitleLabel.leftToSuperview(offset: 10.0)
    anonymousTitleLabel.rightToLeft(of: anonymousPostButton, offset: -10.0)
    anonymousTitleLabel.centerY(to: anonymousPostButton)
    self.anonymousTitleLabel = anonymousTitleLabel
    
    //anonymousOpinionTextViewBG
    let anonymousOpinionTextViewBG = UIView()
    anonymousOpinionTextViewBG.backgroundColor = ANIColor.lightGray
    anonymousOpinionTextViewBG.layer.cornerRadius = 10.0
    anonymousOpinionTextViewBG.layer.masksToBounds = true
    self.addSubview(anonymousOpinionTextViewBG)
    anonymousOpinionTextViewBG.topToBottom(of: anonymousPostButton, offset: 10.0)
    anonymousOpinionTextViewBG.leftToSuperview(offset: 10.0)
    anonymousOpinionTextViewBG.rightToSuperview(offset: -10.0)
    anonymousOpinionTextViewBG.height(200.0)
    self.anonymousOpinionTextViewBG = anonymousOpinionTextViewBG
    
    //anonymousOpinionTextView
    let anonymousOpinionTextView = ANIPlaceHolderTextView()
    anonymousOpinionTextView.font = UIFont.systemFont(ofSize: 15.0)
    anonymousOpinionTextView.textColor = ANIColor.dark
    anonymousOpinionTextView.backgroundColor = .clear
    anonymousOpinionTextView.placeHolder = "どんな意見でもいいので気軽に意見を送ってください*^-^*"
    anonymousOpinionTextViewBG.addSubview(anonymousOpinionTextView)
    let textViewInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    anonymousOpinionTextView.edgesToSuperview(insets: textViewInsets)
    self.anonymousOpinionTextView = anonymousOpinionTextView
    setHideButtonOnKeyboard(textView: anonymousOpinionTextView)
  }
  
  private func setHideButtonOnKeyboard(textView: UITextView){
    let tools = UIToolbar()
    tools.tintColor = ANIColor.emerald
    tools.frame = CGRect(x: 0, y: 0, width: frame.width, height: KEYBOARD_HIDE_TOOL_BAR_HEIGHT)
    let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    let closeButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(keyboardHideButtonTapped))
    tools.items = [spacer, closeButton]
    textView.inputAccessoryView = tools
  }
  
  private func postOpinion() {
    guard let anonymousOpinionTextView = self.anonymousOpinionTextView,
          let text = anonymousOpinionTextView.text,
          text != "",
          let adminUser = self.adminUser,
          let adminUserId = adminUser.uid,
          let unreadMessageCount = adminUser.unreadMessageCount,
          let chatGroup = self.chatGroup,
          let unreadMessageCountForBadge = chatGroup.unreadMessageCountForBadge else { return }
    
    let date = ANIFunction.shared.getToday()
    
    let message = FirebaseChatMessage(sendUserId: "opinionBox", sendUserName: "意見箱", receiveUserId: adminUserId, message: text, date: date, isDiffrentBeforeDate: nil)
    
    let database = Firestore.firestore()
    
    do {
      let message = try FirestoreEncoder().encode(message)
      
      DispatchQueue.global().async {
        var userUnreadMessageCount = 0
        if let unreadMessageCountForBadge = unreadMessageCountForBadge[adminUserId] {
          userUnreadMessageCount = unreadMessageCountForBadge + 1
        }
        
        let value: [String: Any] = [KEY_CHAT_UPDATE_DATE: date, KEY_CHAT_LAST_MESSAGE: text, KEY_IS_HAVE_UNREAD_MESSAGE + "." + adminUserId: true, KEY_UNREAD_MESSAGE_COUNT_FOR_BADGE + "." + adminUserId: userUnreadMessageCount]
        database.collection(KEY_CHAT_GROUPS).document(KEY_OPINION_BOX_CHAT_GROUP).updateData(value)
        
        database.collection(KEY_USERS).document(adminUserId).updateData([KEY_UNREAD_MESSAGE_COUNT: unreadMessageCount + 1])
        
        database.collection(KEY_CHAT_GROUPS).document(KEY_OPINION_BOX_CHAT_GROUP).collection(KEY_CHAT_MESSAGES).addDocument(data: message)
        
        DispatchQueue.main.async {
          anonymousOpinionTextView.text = ""
          anonymousOpinionTextView.showPlaceHolder()
          anonymousOpinionTextView.resignFirstResponder()
          
          self.delegate?.didPostOpinion()
        }
      }
    } catch let error {
      DLog(error)
    }
  }
  
  @objc func keyboardHideButtonTapped(){
    self.endEditing(true)
  }
}

//MARK: ANIButtonViewDelegate
extension ANIOpinionBoxView: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === self.anonymousPostButton {
        postOpinion()
    }
  }
}
