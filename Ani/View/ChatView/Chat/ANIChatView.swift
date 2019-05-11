//
//  ChatView.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/27.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase

protocol ANIChatViewDelegate {
  func loadedMessage(messages: [FirebaseChatMessage])
}

class ANIChatView: UIView {
  
  private weak var chatTableView: UITableView?
    
  var chatGroupId: String? {
    didSet {
      observeChatGroup()
      loadFirstMessage() {
        self.loadMessage()
      }
    }
  }
  
  var user: FirebaseUser?
  
  var chatGroupListener: ListenerRegistration?
  
  var chatGroup: FirebaseChatGroup?
  
  private var messages = [FirebaseChatMessage]() {
    didSet {
      self.delegate?.loadedMessage(messages: messages)
    }
  }
  
  var delegate: ANIChatViewDelegate?
  
  private var beforeDate: String = ""
  
  private var isFirstLoad: Bool = true
  private var isLastPage: Bool = false
  private var lastMessage: QueryDocumentSnapshot?
  private var isLoading: Bool = false
  private let COUNT_FIRST_CELL: Int = 4
  private var firstMessageDocumentId: String?
  private var isLoadFirstMessage: Bool = false
  
  private var cellHeight = [IndexPath: CGFloat]()
  
  private weak var activityIndicatorView: ANIActivityIndicator?

  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = .white
    
    //chatTableView
    let chatTableView = UITableView()
    chatTableView.separatorStyle = .none
    let myChatId = NSStringFromClass(ANIMyChatViewCell.self)
    chatTableView.register(ANIMyChatViewCell.self, forCellReuseIdentifier: myChatId)
    let otherChatId = NSStringFromClass(ANIOtherChatViewCell.self)
    chatTableView.register(ANIOtherChatViewCell.self, forCellReuseIdentifier: otherChatId)
    let activityIndicatorId = NSStringFromClass(ANIChatActivityIndicatorViewCell.self)
    chatTableView.register(ANIChatActivityIndicatorViewCell.self, forCellReuseIdentifier: activityIndicatorId)
    chatTableView.dataSource = self
    chatTableView.delegate = self
    chatTableView.alpha = 0.0
    chatTableView.rowHeight = UITableView.automaticDimension
    addSubview(chatTableView)
    chatTableView.edgesToSuperview()
    self.chatTableView = chatTableView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = false
    self.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  func scrollToBottom() {
    guard let chatTableView = self.chatTableView else { return }
    
    if !messages.isEmpty {
      chatTableView.scrollToRow(at: [0, messages.count - 1], at: .bottom, animated: false)
    }
  }
  
  private func getDate(date: String) -> String {
    let resetDate = String(date.prefix(10))
    
    return resetDate
  }
  
  private func updateTableWithNewRowCount(newMessage: [FirebaseChatMessage]) {
    guard let chatTableView = self.chatTableView else { return }
    
    UIView.setAnimationsEnabled(false)
    CATransaction.begin()

    CATransaction.setCompletionBlock { () -> Void in
      UIView.setAnimationsEnabled(true)
    }
    
    chatTableView.reloadData()
    chatTableView.beginUpdates()
    chatTableView.endUpdates()
  
    let indexPath = IndexPath(row: newMessage.count + 1, section: 0)
    chatTableView.scrollToRow(at: indexPath, at: .top, animated: false)
    
    var contentOffset = chatTableView.contentOffset
    contentOffset.y = contentOffset.y - 30

    chatTableView.setContentOffset(contentOffset, animated: false)
    
    CATransaction.commit()
    
    self.isLoading = false
  }
  
  private func getIsDiffrentBeforeDate(beforeDate: String, date: String) -> Bool {
    if beforeDate != date {
      return true
    } else {
      return false
    }
  }
  
  private func reloadTableView(completion:(()->())? = nil) {
    guard let chatTableView = self.chatTableView,
          let currentUserUid = ANISessionManager.shared.currentUserUid,
          let currentUser = ANISessionManager.shared.currentUser,
          let unreadNotiCount = currentUser.unreadNotiCount,
          let unreadMessageCount = currentUser.unreadMessageCount,
          let chatGroup = self.chatGroup,
          let chatGroupId = self.chatGroupId,
          let unreadMessageCountForBadge = chatGroup.unreadMessageCountForBadge,
          let currentUserUnreadMessageCountForBadge = unreadMessageCountForBadge[currentUserUid],
          let activityIndicatorView = self.activityIndicatorView else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.main.async {
      chatTableView.reloadData() {
        UIApplication.shared.applicationIconBadgeNumber = unreadNotiCount + unreadMessageCount - currentUserUnreadMessageCountForBadge
        database.collection(KEY_USERS).document(currentUserUid).updateData([KEY_UNREAD_MESSAGE_COUNT: unreadMessageCount - currentUserUnreadMessageCountForBadge])
        
        database.collection(KEY_CHAT_GROUPS).document(chatGroupId).updateData([KEY_IS_HAVE_UNREAD_MESSAGE + "." + currentUserUid: false, KEY_UNREAD_MESSAGE_COUNT_FOR_BADGE + "." + currentUserUid: 0])
      }
      
      self.scrollToBottom()
      
      activityIndicatorView.stopAnimating()
      
      UIView.animate(withDuration: 0.2, animations: {
        ANISessionManager.shared.isLoadedFirstData = true
        ANINotificationManager.postDismissSplash()
        
        chatTableView.alpha = 1.0
      })
      
      self.isLoading = false
      
      completion?()
    }
  }
}

//MARK: UITableViewDataSource
extension ANIChatView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if isLoadFirstMessage {
      return messages.count
    } else {
      return messages.count
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let currentUserUid = ANISessionManager.shared.currentUserUid else { return UITableViewCell() }
    if indexPath.row != 0 {
      beforeDate = ANIFunction.shared.getCurrentLocaleDateFromString(string: messages[indexPath.row - 1].date, format: "yyyy/MM/dd")
    }
    let date = ANIFunction.shared.getCurrentLocaleDateFromString(string: messages[indexPath.row].date, format: "yyyy/MM/dd")
    
    if isLoadFirstMessage {
      if messages[indexPath.row].sendUserId == currentUserUid {
        let myChatId = NSStringFromClass(ANIMyChatViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: myChatId, for: indexPath) as! ANIMyChatViewCell
  
        cell.message = messages[indexPath.row]
        if indexPath.row == 0 {
          cell.chagedDate = date
        } else {
          if getIsDiffrentBeforeDate(beforeDate: beforeDate, date: date) {
            cell.chagedDate = date
          } else {
            cell.chagedDate = nil
          }
        }
  
        return cell
      } else {
        let otherChatId = NSStringFromClass(ANIOtherChatViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: otherChatId, for: indexPath) as! ANIOtherChatViewCell
  
        cell.message = messages[indexPath.row]
        cell.user = self.user
        if indexPath.row == 0 {
          cell.chagedDate = date
        } else {
          if getIsDiffrentBeforeDate(beforeDate: beforeDate, date: date) {
            cell.chagedDate = date
          } else {
            cell.chagedDate = nil
          }
        }
        
        return cell
      }
    } else {
      if indexPath.row == 0 {
        let activityIndicatorId = NSStringFromClass(ANIChatActivityIndicatorViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: activityIndicatorId, for: indexPath) as! ANIChatActivityIndicatorViewCell
        
        return cell
      } else {
        if messages[indexPath.row].sendUserId == currentUserUid {
          let myChatId = NSStringFromClass(ANIMyChatViewCell.self)
          let cell = tableView.dequeueReusableCell(withIdentifier: myChatId, for: indexPath) as! ANIMyChatViewCell

          cell.message = messages[indexPath.row]
          if indexPath.row == 0 {
            cell.chagedDate = date
          } else {
            if getIsDiffrentBeforeDate(beforeDate: beforeDate, date: date) {
              cell.chagedDate = date
            } else {
              cell.chagedDate = nil
            }
          }

          return cell
        } else {
          let otherChatId = NSStringFromClass(ANIOtherChatViewCell.self)
          let cell = tableView.dequeueReusableCell(withIdentifier: otherChatId, for: indexPath) as! ANIOtherChatViewCell

          cell.message = messages[indexPath.row]
          cell.user = self.user
          if indexPath.row == 0 {
            cell.chagedDate = date
          } else {
            if getIsDiffrentBeforeDate(beforeDate: beforeDate, date: date) {
              cell.chagedDate = date
            } else {
              cell.chagedDate = nil
            }
          }
          
          return cell
        }
      }
    }
  }
}

//MARK: UITableViewDelegate
extension ANIChatView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    self.cellHeight[indexPath] = cell.frame.size.height
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    if let height = self.cellHeight[indexPath] {
      return height
    } else {
      return UITableView.automaticDimension
    }
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y == 0 {
      loadMoreMessage()
    }
  }
}

//MAKR: data
extension ANIChatView {
  private func loadFirstMessage(completion:(()->())? = nil) {
    guard let chatGroupId = self.chatGroupId,
          let activityIndicatorView = self.activityIndicatorView else { return }
    
    let database = Firestore.firestore()
    
    activityIndicatorView.startAnimating()
    
    DispatchQueue.global().async {
      database.collection(KEY_CHAT_GROUPS).document(chatGroupId).collection(KEY_CHAT_MESSAGES).order(by: KEY_DATE).limit(to: 1).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          completion?()
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        for document in snapshot.documents {
          self.firstMessageDocumentId = document.documentID
          
          completion?()
        }
        
        if snapshot.documents.isEmpty {
          self.isLoadFirstMessage = true
          
          completion?()
        }
      })
    }
  }
  
  private func loadMessage() {
    guard let chatGroupId = self.chatGroupId,
          let activityIndicatorView = self.activityIndicatorView else { return }

    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      self.isLastPage = false

      database.collection(KEY_CHAT_GROUPS).document(chatGroupId).collection(KEY_CHAT_MESSAGES).order(by: KEY_DATE, descending: true).limit(to: 21).getDocuments { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot,
              let lastMessage = snapshot.documents.last else {
                self.isLoading = false
                activityIndicatorView.stopAnimating()
                
                self.isFirstLoad = false
                self.isLoading = false
                return }

        self.lastMessage = lastMessage
        
        for (index, document) in snapshot.documents.enumerated() {
          do {
            let message = try FirestoreDecoder().decode(FirebaseChatMessage.self, from: document.data())
            if let firstMessageDocumentId = self.firstMessageDocumentId {
              if firstMessageDocumentId == document.documentID {
                self.isLoadFirstMessage = true
              }
            }

            self.messages.insert(message, at: 0)

            if index + 1 == snapshot.documents.count {
              self.reloadTableView() {
                self.isFirstLoad = false
              }
            }
          } catch let error {
            DLog(error)

            activityIndicatorView.stopAnimating()

            self.isLoading = false
          }
        }
      }
    }
  }
  
  private func loadMoreMessage() {
    guard let chatGroupId = self.chatGroupId,
          let lastMessage = self.lastMessage,
          !isLoading,
          !isLastPage else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      database.collection(KEY_CHAT_GROUPS).document(chatGroupId).collection(KEY_CHAT_MESSAGES).order(by: KEY_DATE, descending: true).start(afterDocument: lastMessage).limit(to: 21).getDocuments { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        guard let lastMessage = snapshot.documents.last else {
          self.isLastPage = true
          self.isLoading = false
          return }
        
        self.lastMessage = lastMessage
        
        var newMessage = [FirebaseChatMessage]()
        
        for (index, document) in snapshot.documents.enumerated() {
          do {
            if let firstMessageDocumentId = self.firstMessageDocumentId {
              if firstMessageDocumentId == document.documentID {
                self.isLoadFirstMessage = true
              }
            }
            
            let message = try FirestoreDecoder().decode(FirebaseChatMessage.self, from: document.data())
            
            self.messages.insert(message, at: 0)
            newMessage.insert(message, at: 0)
            
            DispatchQueue.main.async {
              if index + 1 == snapshot.documents.count {
                self.updateTableWithNewRowCount(newMessage: newMessage)
              }
            }
          } catch let error {
            DLog(error)
            
            self.isLoading = false
          }
        }
      }
    }
  }
  
  private func observeChatGroup() {
    guard let chatGroupId = self.chatGroupId else { return }
    
    let database = Firestore.firestore()
    
    if let chatGroupListener = self.chatGroupListener {
      chatGroupListener.remove()
    }

    DispatchQueue.global().async {
      self.chatGroupListener = database.collection(KEY_CHAT_GROUPS).document(chatGroupId).collection(KEY_CHAT_MESSAGES).addSnapshotListener({ (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")

          return
        }

        guard let snapshot = snapshot,
              !self.isFirstLoad else { return }

        snapshot.documentChanges.forEach({ (diff) in
          if diff.type == .added {
            do {
              let message = try FirestoreDecoder().decode(FirebaseChatMessage.self, from: diff.document.data())

              self.messages.append(message)
              self.reloadTableView()
            } catch let error {
              DLog(error)
            }
          }
        })
      })
    }
  }
}
