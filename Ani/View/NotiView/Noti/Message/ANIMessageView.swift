//
//  ANIMessageView.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/15.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase

class ANIMessageView: UIView {
  
  private weak var reloadView: ANIReloadView?
  
  private weak var messageTableView: UITableView?
  
  private var chatGroups = [FirebaseChatGroup]()
  
  private var chatGroupListener: ListenerRegistration?
  
  private weak var activityIndicatorView: ANIActivityIndicator?

  var isCellSelected: Bool = false
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
    loadChatGroup()
    setupNotifications()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = ANIColor.bg
    
    //reloadView
    let reloadView = ANIReloadView()
    reloadView.alpha = 0.0
    reloadView.messege = "メッセージがありません。"
    reloadView.delegate = self
    addSubview(reloadView)
    reloadView.dropShadow()
    reloadView.centerInSuperview()
    reloadView.leftToSuperview(offset: 50.0)
    reloadView.rightToSuperview(offset: -50.0)
    self.reloadView = reloadView
    
    //messageTableView
    let messageTableView = UITableView()
    messageTableView.contentInset = UIEdgeInsets(top: ANICommunityViewController.NAVIGATION_BAR_HEIGHT, left: 0, bottom: 0, right: 0)
    messageTableView.scrollIndicatorInsets  = UIEdgeInsets(top: UIViewController.NAVIGATION_BAR_HEIGHT, left: 0, bottom: 0, right: 0)
    let id = NSStringFromClass(ANIMessageViewCell.self)
    messageTableView.register(ANIMessageViewCell.self, forCellReuseIdentifier: id)
    messageTableView.backgroundColor = ANIColor.bg
    messageTableView.separatorStyle = .none
    messageTableView.alwaysBounceVertical = true
    messageTableView.dataSource = self
    messageTableView.alpha = 0.0
    addSubview(messageTableView)
    messageTableView.edgesToSuperview()
    self.messageTableView = messageTableView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = false
    self.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  private func setupNotifications() {
    ANINotificationManager.receive(notiTabTapped: self, selector: #selector(scrollToTop))
    ANINotificationManager.receive(login: self, selector: #selector(reloadChatGroups))
    ANINotificationManager.receive(logout: self, selector: #selector(hideTableView))
    ANINotificationManager.receive(loadedCurrentUser: self, selector: #selector(reloadChatGroups))
    ANINotificationManager.postDidSetupViewNotifications()
  }
  
  @objc private func scrollToTop() {
    guard let messageTableView = messageTableView,
          !chatGroups.isEmpty,
          isCellSelected else { return }
    
    messageTableView.scrollToRow(at: [0, 0], at: .top, animated: true)
  }
  
  @objc private func reloadChatGroups() {
    guard let messageTableView = self.messageTableView else { return }
    
    messageTableView.alpha = 0.0
    
    loadChatGroup()
  }
  
  @objc private func hideTableView() {
    guard let messageTableView = self.messageTableView else { return }
    
    messageTableView.alpha = 0.0
  }
  
  private func isBlockChatGroup(chatGroup: FirebaseChatGroup) -> Bool {
    guard let memberIds = chatGroup.memberIds,
          let currentUserUid = ANISessionManager.shared.currentUserUid else { return false }
    
    var userId = ""
    
    for key in memberIds.keys {
      if key != currentUserUid {
        userId = key
        break
      }
    }
    
    if let blockUserIds = ANISessionManager.shared.blockUserIds, blockUserIds.contains(userId) {
      return true
    }
    if let blockingUserIds = ANISessionManager.shared.blockingUserIds, blockingUserIds.contains(userId) {
      return true
    }

    return false
  }
}

//MARK: UITableViewDataSource
extension ANIMessageView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return chatGroups.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let id = NSStringFromClass(ANIMessageViewCell.self)
    let cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! ANIMessageViewCell
    
    cell.chatGroup = chatGroups[indexPath.row]
    cell.delegate = self
    
    return cell
  }
}

//MARK: ANIMessageViewCellDelegate
extension ANIMessageView: ANIMessageViewCellDelegate {
  func loadedUser() {
    guard let activityIndicatorView = self.activityIndicatorView,
          let messageTableView = self.messageTableView else { return }
    
    activityIndicatorView.stopAnimating()
    
    UIView.animate(withDuration: 0.2) {
      messageTableView.alpha = 1.0
    }
  }
}

//MARK: data
extension ANIMessageView {
  private func loadChatGroup() {
    guard let crrentUserUid = ANISessionManager.shared.currentUserUid,
          let activityIndicatorView = self.activityIndicatorView,
          let reloadView = self.reloadView,
          let messageTableView = self.messageTableView else { return }

    reloadView.alpha = 0.0
    
    let database = Firestore.firestore()
    
    activityIndicatorView.startAnimating()
    
    if !chatGroups.isEmpty {
      chatGroups.removeAll()
    }
    if let chatGroupListener = self.chatGroupListener {
      chatGroupListener.remove()
    }
    
    DispatchQueue.global().async {
      self.chatGroupListener = database.collection(KEY_CHAT_GROUPS).whereField(KEY_CHAT_MEMBER_IDS + "." + crrentUserUid, isEqualTo: true).addSnapshotListener({ (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        guard let snapshot = snapshot else { return }
        
        var chatGroupsTemp = self.chatGroups
        snapshot.documentChanges.forEach({ (diff) in
          if diff.type == .added {
            do {
              let group = try FirebaseDecoder().decode(FirebaseChatGroup.self, from: diff.document.data())
              if !self.isBlockChatGroup(chatGroup: group) {
                chatGroupsTemp.append(group)
                chatGroupsTemp.sort(by: {$0.updateDate > $1.updateDate})
              }
              
              self.chatGroups = chatGroupsTemp

              DispatchQueue.main.async {
                messageTableView.reloadData()
              }
            } catch let error {
              DLog(error)
              
              activityIndicatorView.stopAnimating()
              
              UIView.animate(withDuration: 0.2, animations: {
                reloadView.alpha = 1.0
              })
            }
          } else if diff.type == .modified {
            do {
              let group = try FirebaseDecoder().decode(FirebaseChatGroup.self, from: diff.document.data())
              
              for (index, chatGroupTemp) in chatGroupsTemp.enumerated() {
                if chatGroupTemp.groupId == group.groupId {
                  chatGroupsTemp[index] = group
                  
                  break
                }
              }
              
              chatGroupsTemp.sort(by: {$0.updateDate > $1.updateDate})
              
              self.chatGroups = chatGroupsTemp
              
              DispatchQueue.main.async {                
                messageTableView.reloadData()
              }
            } catch let error {
              DLog(error)
            }
          }
        })
        
        if snapshot.documents.isEmpty {
          activityIndicatorView.stopAnimating()
          
          messageTableView.alpha = 0.0
          
          UIView.animate(withDuration: 0.2, animations: {
            reloadView.alpha = 1.0
          })
        }
      })
    }
  }
}

//MARK: ANIReloadViewDelegate
extension ANIMessageView: ANIReloadViewDelegate {
  func reloadButtonTapped() {
    guard let activityIndicatorView = self.activityIndicatorView,
          let reloadView = self.reloadView else { return }
    
    reloadView.alpha = 0.0
    activityIndicatorView.startAnimating()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      activityIndicatorView.stopAnimating()
      
      UIView.animate(withDuration: 0.2, animations: {
        reloadView.alpha = 1.0
      })
    }
  }
}
