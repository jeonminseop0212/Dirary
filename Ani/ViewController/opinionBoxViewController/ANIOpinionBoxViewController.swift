//
//  ANIOpinionBoxViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/10/29.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase
import TinyConstraints

class ANIOpinionBoxViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBase: UIView?
  private weak var navigationTitleLabel: UILabel?
  private weak var backButton: UIButton?
  
  private weak var opinionBoxView: ANIOpinionBoxView?
  
  private var rejectViewBottomConstraint: Constraint?
  private var rejectViewBottomConstraintOriginalConstant: CGFloat?
  private weak var rejectView: ANIRejectView?
  private var isRejectAnimating: Bool = false
  
  private var chatGroupListener: ListenerRegistration?
  private var adminUserListener: ListenerRegistration?
  
  private var chatGroup: FirebaseChatGroup? {
    didSet {
      guard let opinionBoxView = self.opinionBoxView else { return }
      
      opinionBoxView.chatGroup = chatGroup
    }
  }
  
  private var adminUser: FirebaseUser? {
    didSet {
      guard let opinionBoxView = self.opinionBoxView else { return }
      
      opinionBoxView.adminUser = adminUser
    }
  }
  
  override func viewDidLoad() {
    setup()
    observeAdminUser()
    observeChatGroup()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    guard let chatGroupListener = self.chatGroupListener,
          let adminUserListener = self.adminUserListener else { return }
    
    chatGroupListener.remove()
    adminUserListener.remove()
    
    ANISessionManager.shared.onlineChatGroupId = nil
  }
  
  private func setup() {
    //basic
    self.view.backgroundColor = .white
    
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
    
    //navigationTitleLabel
    let navigationTitleLabel = UILabel()
    navigationTitleLabel.text = "意見箱"
    navigationTitleLabel.textColor = ANIColor.dark
    navigationTitleLabel.font = UIFont.boldSystemFont(ofSize: 17)
    myNavigationBase.addSubview(navigationTitleLabel)
    navigationTitleLabel.centerInSuperview()
    self.navigationTitleLabel = navigationTitleLabel
    
    //backButton
    let backButton = UIButton()
    let backButtonImage = UIImage(named: "backButton")?.withRenderingMode(.alwaysTemplate)
    backButton.setImage(backButtonImage, for: .normal)
    backButton.tintColor = ANIColor.dark
    backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
    myNavigationBase.addSubview(backButton)
    backButton.width(44.0)
    backButton.height(44.0)
    backButton.leftToSuperview()
    backButton.centerYToSuperview()
    self.backButton = backButton
    
    //opinionBoxView
    let opinionBoxView = ANIOpinionBoxView()
    opinionBoxView.delegate = self
    self.view.addSubview(opinionBoxView)
    opinionBoxView.topToBottom(of: myNavigationBar)
    opinionBoxView.edgesToSuperview(excluding: .top)
    self.opinionBoxView = opinionBoxView
    
    //rejectView
    let rejectView = ANIRejectView()
    rejectView.setRejectText("ご意見ありがとうございます。")
    self.view.addSubview(rejectView)
    rejectViewBottomConstraint = rejectView.bottomToTop(of: self.view)
    rejectViewBottomConstraintOriginalConstant = rejectViewBottomConstraint?.constant
    rejectView.leftToSuperview()
    rejectView.rightToSuperview()
    self.rejectView = rejectView
  }
  
  private func showThanksMessage() {
    guard let rejectViewBottomConstraint = self.rejectViewBottomConstraint,
      !isRejectAnimating else { return }
    
    rejectViewBottomConstraint.constant = UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
      self.isRejectAnimating = true
      self.view.layoutIfNeeded()
    }) { (complete) in
      guard let rejectViewBottomConstraint = self.rejectViewBottomConstraint,
        let rejectViewBottomConstraintOriginalConstant = self.rejectViewBottomConstraintOriginalConstant else { return }
      
      rejectViewBottomConstraint.constant = rejectViewBottomConstraintOriginalConstant
      UIView.animate(withDuration: 0.3, delay: 1.0, options: .curveEaseInOut, animations: {
        self.view.layoutIfNeeded()
      }, completion: { (complete) in
        self.isRejectAnimating = false
      })
    }
  }
  
  //MARK: action
  @objc private func back() {
    self.navigationController?.popViewController(animated: true)
  }
}

//MARK: ANIOpinionBoxViewDelegate
extension ANIOpinionBoxViewController: ANIOpinionBoxViewDelegate {
  func didPostOpinion() {
    showThanksMessage()
  }
}

//data
extension ANIOpinionBoxViewController {
  private func observeAdminUser() {
    let database = Firestore.firestore()
    
    let adminUserId = ANISessionManager.shared.adminUserId

    adminUserListener = database.collection(KEY_USERS).document(adminUserId).addSnapshotListener({ (snapshot, error) in
      if let error = error {
        DLog("Error get document: \(error)")
        return
      }
      
      guard let snapshot = snapshot, let data = snapshot.data() else { return }
      
      do {
        let adminUser = try FirestoreDecoder().decode(FirebaseUser.self, from: data)
        
        DispatchQueue.main.async {
          self.adminUser = adminUser
        }
      } catch let error {
        DLog(error)
      }
    })
  }
  
  private func observeChatGroup() {
    let database = Firestore.firestore()
    
    chatGroupListener = database.collection(KEY_CHAT_GROUPS).document(KEY_OPINION_BOX_CHAT_GROUP).addSnapshotListener({ (snapshot, error) in
      if let error = error {
        DLog("Error get document: \(error)")
        return
      }
      
      guard let snapshot = snapshot, let data = snapshot.data() else { return }
      
      do {
        let chatGroup = try FirestoreDecoder().decode(FirebaseChatGroup.self, from: data)
        
        DispatchQueue.main.async {
          self.chatGroup = chatGroup
        }
      } catch let error {
        DLog(error)
      }
    })
  }
}
