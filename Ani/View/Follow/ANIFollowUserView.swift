//
//  ANIFollowUserView.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/27.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase

protocol ANIFollowUserViewDeleate {
  func reject()
}

class ANIFollowUserView: UIView {
  
  private weak var followUserTableView: UITableView?
  
  private weak var activityIndicatorView: ANIActivityIndicator?

  var followUserViewMode: FollowUserViewMode?
  
  var userId: String? {
    didSet {
      guard let followUserViewMode = self.followUserViewMode else { return }
      
      switch followUserViewMode {
      case .following:
        loadFollowingUser(sender: nil)
      case .follower:
        loadFollower(sender: nil)
      }
    }
  }
  
  private var followingUsers = [FirebaseUser]()
  private var followers = [FirebaseUser]()
  
  private var isLastPage: Bool = false
  private var lastContent: QueryDocumentSnapshot?
  private var isLoading: Bool = false
  private let COUNT_LAST_CELL: Int = 4
  
  private var cellHeight = [IndexPath: CGFloat]()
  
  var delegate: ANIFollowUserViewDeleate?

  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = .white
    
    //followUserTableView
    let followUserTableView = UITableView()
    let id = NSStringFromClass(ANIFollowUserViewCell.self)
    followUserTableView.register(ANIFollowUserViewCell.self, forCellReuseIdentifier: id)
    followUserTableView.separatorStyle = .none
    followUserTableView.alpha = 0.0
    followUserTableView.rowHeight = UITableView.automaticDimension
    followUserTableView.dataSource = self
    followUserTableView.delegate = self
    let refreshControl = UIRefreshControl()
    refreshControl.backgroundColor = .clear
    refreshControl.tintColor = ANIColor.moreDarkGray
    refreshControl.addTarget(self, action: #selector(reloadData(sender:)), for: .valueChanged)
    followUserTableView.addSubview(refreshControl)
    addSubview(followUserTableView)
    followUserTableView.edgesToSuperview()
    self.followUserTableView = followUserTableView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = false
    self.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  @objc private func reloadData(sender: UIRefreshControl?) {
    guard let followUserViewMode = self.followUserViewMode else { return }
    
    switch followUserViewMode {
    case .following:
      loadFollowingUser(sender: sender)
    case .follower:
      loadFollower(sender: sender)
    }
  }
  
  private func isBlockUser(user: FirebaseUser) -> Bool {
    guard let userId = user.uid else { return false }
    
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
extension ANIFollowUserView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let followUserViewMode = self.followUserViewMode else { return 0 }
    
    switch followUserViewMode {
    case .following:
      return followingUsers.count
    case .follower:
      return followers.count
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let followUserViewMode = self.followUserViewMode else { return UITableViewCell() }
    
    let id = NSStringFromClass(ANIFollowUserViewCell.self)
    let cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! ANIFollowUserViewCell
    
    switch followUserViewMode {
    case .following:
      if !followingUsers.isEmpty {
        cell.user = followingUsers[indexPath.row]
      }
    case .follower:
      if !followers.isEmpty {
        cell.user = followers[indexPath.row]
      }
    }
    
    cell.delegate = self
    
    return cell
  }
}

//MARK: UITableViewDelegate
extension ANIFollowUserView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard let followUserViewMode = self.followUserViewMode else { return }

    switch followUserViewMode {
    case .following:
      let element = self.followingUsers.count - COUNT_LAST_CELL
      if !isLoading, indexPath.row >= element {
        loadMoreFollowingUser()
      }
    case .follower:
      let element = self.followers.count - COUNT_LAST_CELL
      if !isLoading, indexPath.row >= element {
        loadMoreFollower()
      }
    }
    
    self.cellHeight[indexPath] = cell.frame.size.height
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    if let height = self.cellHeight[indexPath] {
      return height
    } else {
      return UITableView.automaticDimension
    }
  }
}

//MARK: ANIFollowUserViewCellDelegate
extension ANIFollowUserView: ANIFollowUserViewCellDelegate {
  func reject() {
    self.delegate?.reject()
  }
}

//MARK: data
extension ANIFollowUserView {
  private func loadFollowingUser(sender: UIRefreshControl?) {
    guard let userId = self.userId,
          let activityIndicatorView = self.activityIndicatorView,
          let followUserTableView = self.followUserTableView else { return }
    
    if !self.followingUsers.isEmpty {
      self.followingUsers.removeAll()
    }
    
    if sender == nil {
      activityIndicatorView.startAnimating()
    }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      self.isLastPage = false
      
      database.collection(KEY_USERS).document(userId).collection(KEY_FOLLOWING_USER_IDS).order(by: KEY_DATE, descending: true).limit(to: 20).getDocuments { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot,
              let lastContent = snapshot.documents.last else {
                self.isLoading = false
                activityIndicatorView.stopAnimating()
                return }
        
        self.lastContent = lastContent
        
        let group = DispatchGroup()
        var followingUserTemp = [FirebaseUser?]()
        
        for (index, document) in snapshot.documents.enumerated() {
          group.enter()
          followingUserTemp.append(nil)
          
          DispatchQueue(label: "followingUser").async {
            database.collection(KEY_USERS).document(document.documentID).getDocument(completion: { (userSnapshot, userError) in
              if let error = error {
                DLog("Error get user document: \(error)")
                self.isLoading = false
                
                return
              }
              
              guard let userSnapshot = userSnapshot, let data = userSnapshot.data() else {
                group.leave()
                return
              }
              
              do {
                let user = try FirestoreDecoder().decode(FirebaseUser.self, from: data)
                followingUserTemp[index] = user
                
                group.leave()
              } catch let error {
                DLog(error)
                
                group.leave()
              }
            })
          }
        }
        
        group.notify(queue: DispatchQueue(label: "followingUser")) {
          DispatchQueue.main.async {
            if let sender = sender {
              sender.endRefreshing()
            }
            
            for followingUser in followingUserTemp {
              if let followingUser = followingUser {
                if !self.isBlockUser(user: followingUser) {
                  self.followingUsers.append(followingUser)
                }
              }
            }
            followUserTableView.reloadData()
            
            self.isLoading = false

            if self.followingUsers.isEmpty {
              self.loadMoreFollowingUser()
            } else {
              activityIndicatorView.stopAnimating()
              
              UIView.animate(withDuration: 0.2, animations: {
                followUserTableView.alpha = 1.0
              })
            }
          }
        }
      }
    }
  }
  
  private func loadMoreFollowingUser() {
    guard let followUserTableView = self.followUserTableView,
          let lastContent = self.lastContent,
          let userId = self.userId,
          let activityIndicatorView = self.activityIndicatorView,
          !isLoading,
          !isLastPage else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      database.collection(KEY_USERS).document(userId).collection(KEY_FOLLOWING_USER_IDS).order(by: KEY_DATE, descending: true).start(afterDocument: lastContent).limit(to: 20).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        guard let lastContent = snapshot.documents.last else {
          self.isLastPage = true
          self.isLoading = false
          return
        }
        
        self.lastContent = lastContent
        
        let group = DispatchGroup()
        var followingUserTemp = [FirebaseUser?]()
        
        for (index, document) in snapshot.documents.enumerated() {
          
          group.enter()
          followingUserTemp.append(nil)
          
          DispatchQueue(label: "followingUser").async {
            database.collection(KEY_USERS).document(document.documentID).getDocument(completion: { (userSnapshot, userError) in
              if let userError = userError {
                DLog("Error get document: \(userError)")
                self.isLoading = false
                
                return
              }
              
              guard let userSnapshot = userSnapshot, let data = userSnapshot.data() else {
                group.leave()
                return
              }
              
              do {
                let user = try FirestoreDecoder().decode(FirebaseUser.self, from: data)
                followingUserTemp[index] = user
                
                group.leave()
              } catch let error {
                DLog(error)
                
                group.leave()
              }
            })
          }
        }
        
        group.notify(queue: DispatchQueue(label: "followingUser")) {
          DispatchQueue.main.async {
            for followingUser in followingUserTemp {
              if let followingUser = followingUser {
                if !self.isBlockUser(user: followingUser) {
                  self.followingUsers.append(followingUser)
                }
              }
            }
            followUserTableView.reloadData()
            
            self.isLoading = false
            
            if self.followingUsers.isEmpty {
              self.loadMoreFollowingUser()
            } else {
              if followUserTableView.alpha == 0 {
                activityIndicatorView.stopAnimating()
                
                UIView.animate(withDuration: 0.2, animations: {
                  followUserTableView.alpha = 1.0
                })
              }
            }
          }
        }
      })
    }
  }
  
  private func loadFollower(sender: UIRefreshControl?) {
    guard let userId = self.userId,
          let activityIndicatorView = self.activityIndicatorView,
          let followUserTableView = self.followUserTableView else { return }
    
    if !self.followers.isEmpty {
      self.followers.removeAll()
    }
    
    if sender == nil {
      activityIndicatorView.startAnimating()
    }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      self.isLastPage = false
      
      database.collection(KEY_USERS).document(userId).collection(KEY_FOLLOWER_IDS).order(by: KEY_DATE, descending: true).limit(to: 20).getDocuments { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot,
              let lastContent = snapshot.documents.last else {
                self.isLoading = false
                activityIndicatorView.stopAnimating()
                
                if let sender = sender {
                  sender.endRefreshing()
                }
                return }
        
        self.lastContent = lastContent
        
        let group = DispatchGroup()
        var followUserTemp = [FirebaseUser?]()
        
        for (index, document) in snapshot.documents.enumerated() {
          
          group.enter()
          followUserTemp.append(nil)
          
          DispatchQueue(label: "follower").async {
            database.collection(KEY_USERS).document(document.documentID).getDocument(completion: { (userSnapshot, userError) in
              if let error = error {
                DLog("Error get user document: \(error)")
                self.isLoading = false
                
                return
              }
              
              guard let userSnapshot = userSnapshot, let data = userSnapshot.data() else {
                group.leave()
                return
              }
              
              do {
                let user = try FirestoreDecoder().decode(FirebaseUser.self, from: data)
                followUserTemp[index] = user
                
                group.leave()
              } catch let error {
                DLog(error)
                
                group.leave()
              }
            })
          }
        }
        
        group.notify(queue: DispatchQueue(label: "follower")) {
          DispatchQueue.main.async {
            DispatchQueue.main.async {
              if let sender = sender {
                sender.endRefreshing()
              }
              
              for follower in followUserTemp {
                if let follower = follower {
                  if !self.isBlockUser(user: follower) {
                    self.followers.append(follower)
                  }
                }
              }
              
              followUserTableView.reloadData()
              
              self.isLoading = false

              if self.followers.isEmpty {
                self.loadMoreFollower()
              } else {
                activityIndicatorView.stopAnimating()
                
                UIView.animate(withDuration: 0.2, animations: {
                  followUserTableView.alpha = 1.0
                })
              }
            }
          }
        }
      }
    }
  }
  
  private func loadMoreFollower() {
    guard let followUserTableView = self.followUserTableView,
          let lastContent = self.lastContent,
          let userId = self.userId,
          let activityIndicatorView = self.activityIndicatorView,
          !isLoading,
          !isLastPage else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      database.collection(KEY_USERS).document(userId).collection(KEY_FOLLOWER_IDS).order(by: KEY_DATE, descending: true).start(afterDocument: lastContent).limit(to: 20).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        guard let lastContent = snapshot.documents.last else {
          self.isLastPage = true
          self.isLoading = false
          return
        }
        
        self.lastContent = lastContent
        
        let group = DispatchGroup()
        var followerTemp = [FirebaseUser?]()
        
        for (index, document) in snapshot.documents.enumerated() {
          
          group.enter()
          followerTemp.append(nil)
          
          DispatchQueue(label: "follower").async {
            database.collection(KEY_USERS).document(document.documentID).getDocument(completion: { (userSnapshot, userError) in
              if let userError = userError {
                DLog("Error get document: \(userError)")
                self.isLoading = false
                
                return
              }
              
              guard let userSnapshot = userSnapshot, let data = userSnapshot.data() else {
                group.leave()
                return
              }
              
              do {
                let user = try FirestoreDecoder().decode(FirebaseUser.self, from: data)
                followerTemp[index] = user
                
                group.leave()
              } catch let error {
                DLog(error)
                
                group.leave()
              }
            })
          }
        }
        
        group.notify(queue: DispatchQueue(label: "follower")) {
          DispatchQueue.main.async {
            for follower in followerTemp {
              if let follower = follower {
                if !self.isBlockUser(user: follower) {
                  self.followers.append(follower)
                }
              }
            }
            followUserTableView.reloadData()
            
            self.isLoading = false
            
            if self.followers.isEmpty {
              self.loadMoreFollower()
            } else {
              if followUserTableView.alpha == 0 {
                activityIndicatorView.stopAnimating()
                
                UIView.animate(withDuration: 0.2, animations: {
                  followUserTableView.alpha = 1.0
                })
              }
            }
          }
        }
      })
    }
  }
}
