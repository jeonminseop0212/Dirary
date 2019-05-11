//
//  ANIChatViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/27.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints
import FirebaseFirestore
import CodableFirebase

class ANIChatViewController: UIViewController {
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBase: UIView?
  private weak var backButton: UIButton?
  private weak var navigationTitleLabel: UILabel?
  
  private weak var chatView: ANIChatView?
  
  private var chatBarBottomConstraint: Constraint?
  private var chatBarOriginalBottomConstraintConstant: CGFloat?
  private weak var chatBar: ANIChatBar?
  
  var user: FirebaseUser? {
    didSet {
      checkGroup()
    }
  }
  
  var chatGroup: FirebaseChatGroup? {
    didSet {
      guard let chatView = self.chatView,
            let chatBar = self.chatBar else { return }
      
      chatView.chatGroup = chatGroup
      chatBar.chatGroup = chatGroup
    }
  }
  
  private var chatGroupId: String? {
    didSet {
      guard let chatView = self.chatView,
            let chatBar = self.chatBar else { return }
      
      chatView.chatGroupId = chatGroupId
      chatView.user = user
      chatBar.chatGroupId = chatGroupId
      chatBar.user = user
      
      ANISessionManager.shared.onlineChatGroupId = chatGroupId
      
      observeChatGroup()
      chatBar.observeUser()
    }
  }
  
  private var isHaveGroup: Bool = false {
    didSet {
      guard let chatBar = self.chatBar else { return }
      
      chatBar.isHaveGroup = isHaveGroup
    }
  }
  
  var isPush: Bool = false
  
  private var chatGroupListener: ListenerRegistration?
  
  override func viewDidLoad() {
    setup()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    setupNotifications()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    UIApplication.shared.statusBarStyle = .default
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    removeNotifications()
    removeGroup()
    
    guard let chatView = self.chatView,
          let chatViewChatGroupListener = chatView.chatGroupListener,
          let chatBarChatGroupListener = self.chatGroupListener,
          let chatBar = self.chatBar,
          let userListener = chatBar.userListener else { return }
    
    chatViewChatGroupListener.remove()
    chatBarChatGroupListener.remove()
    userListener.remove()
    
    ANISessionManager.shared.onlineChatGroupId = nil
  }
    
  private func setup() {
    //basic
    self.view.backgroundColor = .white
    self.navigationController?.setNavigationBarHidden(true, animated: false)
    self.navigationController?.navigationBar.isTranslucent = false
    self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    ANIOrientation.lockOrientation(.portrait)
    
    //myNavigationBar
    let myNavigationBar = UIView()
    myNavigationBar.backgroundColor = .white
    self.view.addSubview(myNavigationBar)
    myNavigationBar.topToSuperview()
    myNavigationBar.leftToSuperview()
    myNavigationBar.rightToSuperview()
    myNavigationBar.height(UIViewController.STATUS_BAR_HEIGHT + UIViewController.NAVIGATION_BAR_HEIGHT)
    self.myNavigationBar = myNavigationBar
    
    //myNavigationBase
    let myNavigationBase = UIView()
    myNavigationBar.addSubview(myNavigationBase)
    myNavigationBase.edgesToSuperview(excluding: .top)
    myNavigationBase.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    self.myNavigationBase = myNavigationBase
    
    //backButton
    let backButton = UIButton()
    if isPush {
      let backButtonImage = UIImage(named: "backButton")?.withRenderingMode(.alwaysTemplate)
      backButton.setImage(backButtonImage, for: .normal)
    } else {
      let backButtonImage = UIImage(named: "dismissButton")?.withRenderingMode(.alwaysTemplate)
      backButton.setImage(backButtonImage, for: .normal)
    }
    backButton.tintColor = ANIColor.dark
    backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
    myNavigationBase.addSubview(backButton)
    backButton.width(44.0)
    backButton.height(44.0)
    backButton.leftToSuperview()
    backButton.centerYToSuperview()
    self.backButton = backButton
    
    //navigationTitleLabel
    let navigationTitleLabel = UILabel()
    if let user = self.user, let userName = user.userName {
      navigationTitleLabel.text = userName
    }
    navigationTitleLabel.textColor = ANIColor.dark
    navigationTitleLabel.font = UIFont.boldSystemFont(ofSize: 17)
    myNavigationBase.addSubview(navigationTitleLabel)
    navigationTitleLabel.centerInSuperview()
    self.navigationTitleLabel = navigationTitleLabel
    
    //chatBar
    let chatBar = ANIChatBar()
    if let chatGroupId = self.chatGroupId {
      chatBar.user = user
      chatBar.chatGroupId = chatGroupId
    }
    self.view.addSubview(chatBar)
    chatBar.leftToSuperview()
    chatBar.rightToSuperview()
    chatBarBottomConstraint = chatBar.bottomToSuperview(usingSafeArea: true)
    chatBarOriginalBottomConstraintConstant = chatBarBottomConstraint?.constant
    self.chatBar = chatBar
    
    //chatView
    let chatView = ANIChatView()
    if let chatGroupId = self.chatGroupId {
      chatView.user = user
      chatView.chatGroupId = chatGroupId
    }
    chatView.delegate = self
    self.view.addSubview(chatView)
    chatView.topToBottom(of: myNavigationBar)
    chatView.leftToSuperview()
    chatView.rightToSuperview()
    chatView.bottomToTop(of: chatBar)
    self.chatView = chatView
  }
  
  private func checkGroup() {
    guard let currentUserUid = ANISessionManager.shared.currentUserUid,
          let user = self.user,
          let userId = user.uid else { return }
    
    let database = Firestore.firestore()

    DispatchQueue.global().async {
      database.collection(KEY_CHAT_GROUPS).whereField(KEY_CHAT_MEMBER_IDS + "." + currentUserUid, isEqualTo: true).whereField(KEY_CHAT_MEMBER_IDS + "." + userId, isEqualTo: true).getDocuments { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        for document in snapshot.documents {
          self.chatGroupId = document.documentID
          self.isHaveGroup = true
          
          do {
            let chatGroup = try FirestoreDecoder().decode(FirebaseChatGroup.self, from: document.data())
            self.chatGroup = chatGroup
          } catch let error {
            DLog(error)
          }
        }
        
        if snapshot.documents.isEmpty {
          self.createGroup()
        }
      }
    }
  }
  
  private func createGroup() {
    let id = NSUUID().uuidString
    let date = ANIFunction.shared.getToday()
    var unreadMessageCountForBadge = [String: Int]()
    if let currentUserUid = ANISessionManager.shared.currentUserUid, let user = self.user, let userId = user.uid {
      unreadMessageCountForBadge = [currentUserUid: 0, userId: 0]
    }
    let chatGroup = FirebaseChatGroup(groupId:id, memberIds: nil, updateDate: date, lastMessage: "", checkChatGroupDate: nil, isHaveUnreadMessage: nil, unreadMessageCountForBadge: unreadMessageCountForBadge)
    
    let database = Firestore.firestore()

    DispatchQueue.global().async {
      do {
        let data = try FirestoreEncoder().encode(chatGroup)
        database.collection(KEY_CHAT_GROUPS).document(id).setData(data, completion: { (error) in
          if let error = error {
            DLog("Error get document: \(error)")
            
            return
          }
          
          self.chatGroupId = id
          self.chatGroup = chatGroup
        })
      } catch let error {
        DLog(error)
      }
    }
  }
  
  private func removeGroup() {
    guard let chatGroupId = self.chatGroupId else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      database.collection(KEY_CHAT_GROUPS).document(chatGroupId).getDocument { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        guard let snapshot = snapshot, let data = snapshot.data() else { return }
        
        do {
          let chatGroup = try FirestoreDecoder().decode(FirebaseChatGroup.self, from: data)
          
          if chatGroup.lastMessage == "" {
            database.collection(KEY_CHAT_GROUPS).document(chatGroupId).delete()
            
            self.chatGroupId = nil
          }
        } catch let error {
          DLog(error)
        }
      }
    }
  }
  
  //MARK: notification
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(keyboardWillChangeFrame: self, selector: #selector(keyboardWillChangeFrame))
    ANINotificationManager.receive(keyboardWillHide: self, selector: #selector(keyboardWillHide))
    ANINotificationManager.receive(profileImageViewTapped: self, selector: #selector(pushOtherProfile))
    ANINotificationManager.receive(applicationWillResignActive: self, selector: #selector(willResignActivity))
    ANINotificationManager.receive(applicationWillEnterForeground: self, selector: #selector(willEnterForeground))
  }
  
  private func removeNotifications() {
    ANINotificationManager.remove(self)
  }
  
  @objc private func keyboardWillChangeFrame(_ notification: Notification) {
    guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
          let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
          let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
          let commentBarBottomConstraint = self.chatBarBottomConstraint,
          let window = UIApplication.shared.keyWindow,
          let chatView = self.chatView else { return }
    
    let h = keyboardFrame.height
    let bottomSafeArea = window.safeAreaInsets.bottom
    
    commentBarBottomConstraint.constant = -h + bottomSafeArea
    
    UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
      self.view.layoutIfNeeded()
    })
    
    chatView.scrollToBottom()
  }
  
  @objc private func keyboardWillHide(_ notification: Notification) {
    guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
          let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
          let commentBarOriginalBottomConstraintConstant = self.chatBarOriginalBottomConstraintConstant,
          let commentBarBottomConstraint = self.chatBarBottomConstraint else { return }
    
    commentBarBottomConstraint.constant = commentBarOriginalBottomConstraintConstant
    
    UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
      self.view.layoutIfNeeded()
    })
  }
  
  @objc private func pushOtherProfile(_ notification: NSNotification) {
    guard let userId = notification.object as? String else { return }

    let otherProfileViewController = ANIOtherProfileViewController()
    otherProfileViewController.hidesBottomBarWhenPushed = true
    otherProfileViewController.userId = userId
    self.navigationController?.pushViewController(otherProfileViewController, animated: true)
  }
  
  @objc private func willResignActivity() {
    if !isHaveGroup {
      removeGroup()
    }
  }
  
  @objc private func willEnterForeground() {
    if !isHaveGroup {
      checkGroup()
    }
  }
  
  //MARK: Action
  @objc private func back() {
    self.view.endEditing(true)
    
    if isPush {
      self.navigationController?.popViewController(animated: true)
    } else {
      self.dismiss(animated: true)
    }
  }
}

//MARK: UIGestureRecognizerDelegate
extension ANIChatViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}

//MARK: ANIChatViewDelegate
extension ANIChatViewController: ANIChatViewDelegate {
  func loadedMessage(messages: [FirebaseChatMessage]) {
    guard let chatBar = self.chatBar else { return }
    
    chatBar.messages = messages
  }
}

//data
extension ANIChatViewController {
  private func observeChatGroup() {
    guard let chatGroupId = self.chatGroupId else { return }
    
    let database = Firestore.firestore()
    
    if chatGroupListener != nil {
      chatGroupListener?.remove()
    }
    
    chatGroupListener = database.collection(KEY_CHAT_GROUPS).document(chatGroupId).addSnapshotListener({ (snapshot, error) in
      if let error = error {
        DLog("Error get document: \(error)")
        return
      }
      
      guard let snapshot = snapshot, let value = snapshot.data() else { return }
      
      do {
        let chatGroup = try FirestoreDecoder().decode(FirebaseChatGroup.self, from: value)
        
        DispatchQueue.main.async {
          self.chatGroup = chatGroup
        }
      } catch let error {
        DLog(error)
      }
    })
  }
}
