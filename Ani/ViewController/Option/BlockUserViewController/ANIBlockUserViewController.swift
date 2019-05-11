//
//  ANIBlockUserViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/11/12.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ANIBlockUserViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBase: UIView?
  private weak var navigationTitleLabel: UILabel?
  private weak var backButton: UIButton?
  
  private weak var blockUserView: ANIBlockUserView?
  
  override func viewDidLoad() {
    setup()
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
    navigationTitleLabel.text = "ブロックユーザー"
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
    
    //blockUserView
    let blockUserView = ANIBlockUserView()
    blockUserView.delegate = self
    self.view.addSubview(blockUserView)
    blockUserView.topToBottom(of: myNavigationBar)
    blockUserView.edgesToSuperview(excluding: .top)
    self.blockUserView = blockUserView
  }
  
  private func block(user: FirebaseUser, isBlock: Bool) {
    guard let userId = user.uid,
          let currentUserUid = ANISessionManager.shared.currentUserUid,
          let userName = user.userName else { return }
    
    if isBlock {
      let alertController = UIAlertController(title: "\(userName)さんのブロックを解除しますか？", message: "ブロック解除された人はあなたのプロフィールや投稿を見られるようになります。", preferredStyle: .alert)
      
      let unblockAction = UIAlertAction(title: "ブロック解除", style: .default) { (action) in
        let database = Firestore.firestore()
        let group = DispatchGroup()
        
        group.enter()
        DispatchQueue(label: "deleteBlockUser").async {
          database.collection(KEY_USERS).document(currentUserUid).collection(KEY_BLOCK_USER_IDS).document(userId).delete(completion: { (error) in
            if let error = error {
              DLog("Error get delete document: \(error)")
              return
            }
            group.leave()
          })
        }
        
        group.enter()
        DispatchQueue(label: "deleteBlockUser").async {
          database.collection(KEY_USERS).document(userId).collection(KEY_BLOCKING_USER_IDS).document(currentUserUid).delete(completion: { (error) in
            if let error = error {
              DLog("Error get delete document: \(error)")
              return
            }
            group.leave()
          })
        }
        
        group.notify(queue: DispatchQueue(label: "deleteBlockUser")) {
          DispatchQueue.main.async {
            guard let blockUserView = self.blockUserView else { return }
            
            blockUserView.reloadTableView()
          }
        }
      }
      let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
      
      alertController.addAction(unblockAction)
      alertController.addAction(cancelAction)
      
      self.present(alertController, animated: true, completion: nil)
    } else {
      let alertController = UIAlertController(title: "\(userName)さんをブロックしますか？", message: "ブロックされた人はあなたのプロフィールや投稿を見られなくなります。ブロックしたことは相手に通知されません。", preferredStyle: .alert)
      
      let blockAction = UIAlertAction(title: "ブロック", style: .default) { (action) in
        let database = Firestore.firestore()
        let group = DispatchGroup()
        let today = ANIFunction.shared.getToday()
        
        group.enter()
        DispatchQueue(label: "blockUser").async {
          database.collection(KEY_USERS).document(currentUserUid).collection(KEY_BLOCK_USER_IDS).document(userId).setData([KEY_USER_ID: userId, KEY_DATE: today], completion: { (error) in
            if let error = error {
              DLog("Error get delete document: \(error)")
              return
            }
            group.leave()
          })
        }
        
        group.enter()
        DispatchQueue(label: "blockUser").async {
          database.collection(KEY_USERS).document(userId).collection(KEY_BLOCKING_USER_IDS).document(currentUserUid).setData([KEY_USER_ID: currentUserUid, KEY_DATE: today], completion: { (error) in
            if let error = error {
              DLog("Error get delete document: \(error)")
              return
            }
            group.leave()
          })
        }
        
        group.notify(queue: DispatchQueue(label: "blockUser")) {
          DispatchQueue.main.async {
            guard let blockUserView = self.blockUserView else { return }
            
            blockUserView.reloadTableView()
          }
        }
      }
      let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
      
      alertController.addAction(blockAction)
      alertController.addAction(cancelAction)
      
      self.present(alertController, animated: true, completion: nil)
    }
  }
  
  //MARK: action
  @objc private func back() {
    self.navigationController?.popViewController(animated: true)
  }
}

//MARK: ANIBlockUserViewDelegate
extension ANIBlockUserViewController: ANIBlockUserViewDelegate {
  func blockButtonTapped(user: FirebaseUser, isBlock: Bool) {
    block(user: user, isBlock: isBlock)
  }
}
