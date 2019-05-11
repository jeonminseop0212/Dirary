//
//  ChatBar.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/28.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import GrowingTextView
import FirebaseFirestore
import CodableFirebase

class ANIChatBar: UIView {
  
  private weak var profileImageView: UIImageView?
  
  private weak var chatTextViewBG: UIView?
  private weak var chatTextView: GrowingTextView?
  
  private weak var postMessageButton: UIButton?
  
  var chatGroupId: String?
  var chatGroup: FirebaseChatGroup?
  
  var user: FirebaseUser?
  
  var isHaveGroup: Bool = false
  
  var messages = [FirebaseChatMessage]()
  
  var userListener: ListenerRegistration?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
    setProfileImage()
    setupNotifications()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //profileImageView
    let profileImageView = UIImageView()
    profileImageView.backgroundColor = ANIColor.gray
    profileImageView.layer.cornerRadius = 40.0 / 2
    profileImageView.layer.masksToBounds = true
    profileImageView.contentMode = .scaleAspectFill
    addSubview(profileImageView)
    profileImageView.width(40.0)
    profileImageView.height(40.0)
    profileImageView.bottomToSuperview(offset: -10.0)
    profileImageView.leftToSuperview(offset: 10.0)
    self.profileImageView = profileImageView
    
    //chatTextViewBG
    let chatTextViewBG = UIView()
    chatTextViewBG.layer.cornerRadius = profileImageView.layer.cornerRadius
    chatTextViewBG.layer.masksToBounds = true
    chatTextViewBG.layer.borderColor = ANIColor.gray.cgColor
    chatTextViewBG.layer.borderWidth = 1.0
    addSubview(chatTextViewBG)
    let bgInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    chatTextViewBG.leftToRight(of: profileImageView, offset: 10.0)
    chatTextViewBG.edgesToSuperview(excluding: .left, insets: bgInsets)
    self.chatTextViewBG = chatTextViewBG
    
    //postMessageButton
    let postMessageButton = UIButton()
    postMessageButton.setTitle("送信する", for: .normal)
    postMessageButton.setTitleColor(ANIColor.emerald, for: .normal)
    postMessageButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
    postMessageButton.addTarget(self, action: #selector(postMessage), for: .touchUpInside)
    postMessageButton.isEnabled = false
    postMessageButton.alpha = 0.3
    chatTextViewBG.addSubview(postMessageButton)
    postMessageButton.rightToSuperview(offset: -10.0)
    postMessageButton.centerY(to: profileImageView)
    postMessageButton.height(to: profileImageView)
    postMessageButton.width(60.0)
    self.postMessageButton = postMessageButton
    
    //chattTextView
    let chatTextView = GrowingTextView()
    chatTextView.textColor = ANIColor.dark
    chatTextView.font = UIFont.systemFont(ofSize: 15.0)
    chatTextView.placeholder = "メッセージ"
    chatTextView.showsVerticalScrollIndicator = false
    if let lineHeight = chatTextView.font?.lineHeight {
      chatTextView.minHeight = 30.0
      chatTextView.maxHeight = lineHeight * 6
    }
    chatTextView.delegate = self
    chatTextViewBG.addSubview(chatTextView)
    let insets = UIEdgeInsets(top: 2.5, left: 5.0, bottom: 2.5, right: 5.0)
    chatTextView.edgesToSuperview(excluding: .right,insets: insets)
    chatTextView.rightToLeft(of: postMessageButton, offset: -5.0)
    self.chatTextView = chatTextView
  }
  
  private func setupNotifications() {
    ANINotificationManager.receive(viewScrolled: self, selector: #selector(keyboardHide))
  }
  
  private func setProfileImage() {
    guard let currentUser = ANISessionManager.shared.currentUser,
          let profileImageUrl = currentUser.profileImageUrl,
          let profileImageView = self.profileImageView else { return }
    
    profileImageView.sd_setImage(with: URL(string: profileImageUrl), completed: nil)
  }
  
  @objc private func keyboardHide() {
    guard let chatTextView = self.chatTextView else { return }
    
    chatTextView.endEditing(true)
  }
  
  private func updateCommentContributionButton(text: String) {
    guard let postMessageButton = self.postMessageButton else { return }
    
    if text.count > 0 {
      postMessageButton.isEnabled = true
      postMessageButton.alpha = 1.0
    } else {
      postMessageButton.isEnabled = false
      postMessageButton.alpha = 0.3
    }
  }
  
  private func checkMember() {
    guard let user = self.user,
          let userId = user.uid,
          let currentUserUid = ANISessionManager.shared.currentUserUid,
          let chatGroupId = self.chatGroupId else { return }
    
    if !isHaveGroup {
      let database = Firestore.firestore()
      
      DispatchQueue.global().async {
        let memberIds = [currentUserUid: true, userId: true]
        database.collection(KEY_CHAT_GROUPS).document(chatGroupId).updateData([KEY_CHAT_MEMBER_IDS: memberIds])
      }
    }
  }
  
  //MARK: action
  @objc private func postMessage() {
    guard let chatTextView = self.chatTextView,
          let text = chatTextView.text,
          let currentUser = ANISessionManager.shared.currentUser,
          let currentUserName = currentUser.userName,
          let currentuserUid = ANISessionManager.shared.currentUserUid,
          let chatGroupId = self.chatGroupId,
          let user = self.user,
          let userId = user.uid,
          let unreadMessageCount = user.unreadMessageCount,
          let chatGroup = self.chatGroup,
          let unreadMessageCountForBadge = chatGroup.unreadMessageCountForBadge else { return }

    let date = ANIFunction.shared.getToday()
    
    let message = FirebaseChatMessage(sendUserId: currentuserUid, sendUserName: currentUserName, receiveUserId: userId, message: text, date: date, isDiffrentBeforeDate: nil)
    
    checkMember()

    let database = Firestore.firestore()
    
    do {
      let message = try FirestoreEncoder().encode(message)
      
      DispatchQueue.global().async {
        var userUnreadMessageCount = 0
        if let unreadMessageCountForBadge = unreadMessageCountForBadge[userId] {
          userUnreadMessageCount = unreadMessageCountForBadge + 1
        }

        let value: [String: Any] = [KEY_CHAT_UPDATE_DATE: date, KEY_CHAT_LAST_MESSAGE: text, KEY_IS_HAVE_UNREAD_MESSAGE + "." + userId: true, KEY_UNREAD_MESSAGE_COUNT_FOR_BADGE + "." + userId: userUnreadMessageCount]
        database.collection(KEY_CHAT_GROUPS).document(chatGroupId).updateData(value)
        
        database.collection(KEY_USERS).document(userId).updateData([KEY_UNREAD_MESSAGE_COUNT: unreadMessageCount + 1])
        
        database.collection(KEY_CHAT_GROUPS).document(chatGroupId).collection(KEY_CHAT_MESSAGES).addDocument(data: message)
      }
    } catch let error {
      DLog(error)
    }

    chatTextView.text = ""
    updateCommentContributionButton(text: chatTextView.text)
  }
}

//MARK: GrowingTextViewDelegate
extension ANIChatBar: GrowingTextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    updateCommentContributionButton(text: textView.text)
  }
}

//data
extension ANIChatBar {
  func observeUser() {
    guard let user = self.user,
          let userId = user.uid else { return }
    
    let database = Firestore.firestore()
    DispatchQueue.global().async {
      self.userListener = database.collection(KEY_USERS).document(userId).addSnapshotListener { (snapshot, error) in
        guard let snapshot = snapshot, let data = snapshot.data() else { return }
        
        do {
          let user = try FirestoreDecoder().decode(FirebaseUser.self, from: data)
          
          self.user = user
        } catch let error {
          DLog(error)
        }
      }
    }
  }
}
